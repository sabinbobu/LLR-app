import Foundation
import Observation
import SwiftData

/// A record just set, for the live banner. `id` is fresh per event so re-triggering on the same
/// exercise (e.g. two PR sets in a row) still restarts the auto-dismiss timer.
struct RecordEvent: Equatable, Identifiable {
    let id = UUID()
    let exerciseName: String
    let kinds: [PersonalRecords.Kind]
}

@MainActor
@Observable
final class ActiveWorkoutModel {
    let workout: Workout
    let restTimer = RestTimer.shared
    /// Editing a finished workout: no rest timer, and the Lock Screen is never touched —
    /// it only ever mirrors the workout in progress.
    let isHistory: Bool
    /// Set by `toggle` when a completed set breaks a record; the view clears it after showing the banner.
    var recordEvent: RecordEvent?
    /// Set by a delete; the view offers Undo for a few seconds, then clears it.
    var removal: UndoableRemoval?

    init(workout: Workout, isHistory: Bool = false) {
        self.workout = workout
        self.isHistory = isHistory
    }

    private var context: ModelContext? { workout.modelContext }

    var defaultRestSeconds: Int {
        UserDefaults.standard.object(forKey: StorageKey.restSeconds) as? Int ?? RestDuration.defaultSeconds
    }

    func history(for exercise: Exercise) -> [Session] {
        exercise.sessions(excluding: workout, section: workout.section)
    }

    func add(_ exercise: Exercise) {
        guard let context else { return }
        let isFirst = workout.exercises.isEmpty
        let entry = WorkoutExercise(order: (workout.exercises.map(\.order).max() ?? -1) + 1)
        context.insert(entry)
        entry.exercise = exercise
        workout.exercises.append(entry)
        let history = history(for: exercise)
        if let timed = TimedWarmup.prefill(muscleGroup: exercise.muscleGroup, name: exercise.name, history: history, isFirstInWorkout: isFirst) {
            appendSet(to: entry, prefill: timed)
            syncLockScreen()
            return
        }
        // Mirror last session's set count so a repeat day is pure check-tapping.
        for index in 0..<max(PreviousPerformance.latestSets(in: history).count, 1) {
            appendSet(to: entry, prefill: exercise.progressionPrefill(index: index, history: history, currentLast: nil))
        }
        syncLockScreen()
    }

    /// A Kineto catalog pick: each new set gets the chosen level's dose directly, not history-based
    /// prefill — progression here is a manual, physio-directed level choice, not double progression.
    func add(_ exercise: Exercise, level: KinetoCatalog.Level) {
        guard let context else { return }
        let entry = WorkoutExercise(order: (workout.exercises.map(\.order).max() ?? -1) + 1)
        context.insert(entry)
        entry.exercise = exercise
        workout.exercises.append(entry)
        for _ in 0..<max(level.sets ?? 1, 1) {
            appendSet(to: entry, prefill: SetValue(weightKg: 0, reps: level.reps ?? 1, durationSeconds: level.durationSeconds))
        }
        syncLockScreen()
    }

    func addSet(to entry: WorkoutExercise) {
        let history = entry.exercise.map(history(for:)) ?? []
        let last = entry.orderedSets.last?.value
        let prefill = entry.exercise?.progressionPrefill(index: entry.sets.count, history: history, currentLast: last)
            ?? PreviousPerformance.prefill(index: entry.sets.count, previous: [], currentLast: last)
        appendSet(to: entry, prefill: prefill)
        syncLockScreen()
    }

    func appendSet(to entry: WorkoutExercise, prefill: SetValue?) {
        guard let context else { return }
        let set = SetEntry(
            order: (entry.sets.map(\.order).max() ?? -1) + 1,
            weightKg: prefill?.weightKg ?? 0,
            reps: prefill?.reps ?? 0
        )
        set.kind = prefill?.kind ?? .normal
        set.durationSeconds = prefill?.durationSeconds
        context.insert(set)
        entry.sets.append(set)
    }

    /// Returns false when the set can't be completed (no reps), so the row can signal it.
    @discardableResult
    func toggle(_ set: SetEntry) -> Bool {
        // Autosave timing isn't guaranteed at an arbitrary kill; a ticked set must survive force-quit.
        defer { try? context?.save() }
        if set.completedAt != nil {
            set.completedAt = nil
            return true
        }
        guard set.reps > 0 else { return false }
        if isHistory {
            // The set happened during that workout, not now, and nobody is resting.
            set.completedAt = workout.startedAt
            return true
        }
        set.completedAt = .now
        let exercise = set.workoutExercise?.exercise
        // Mid-superset the next exercise follows straight on; the rest comes once the round is done.
        if !endsRound(set) {
            syncLockScreen()
        } else if TimedWarmup.isTimedWarmup(kind: set.kind, durationSeconds: set.durationSeconds) {
            restTimer.skip()
        } else if let seconds = RestDuration.resolve(override: exercise?.restSeconds, defaultSeconds: defaultRestSeconds) {
            restTimer.start(seconds: seconds, exerciseName: exercise?.name)
        } else {
            restTimer.skip()
        }
        announceRecord(for: set)
        return true
    }

    /// Gym only: PR hype has no place in a back-care session.
    private func announceRecord(for set: SetEntry) {
        guard workout.section == .gym,
              let entry = set.workoutExercise,
              let name = entry.exercise?.name,
              let index = entry.orderedSets.firstIndex(where: { $0.persistentModelID == set.persistentModelID })
        else { return }
        let kinds = entry.recordKinds()[index]
        guard !kinds.isEmpty else { return }
        recordEvent = RecordEvent(exerciseName: name, kinds: kinds.sorted())
    }

    /// Unchecked sets are drafts, not history: drop them so they never pollute previous-value lookups.
    /// Returns whether anything is left.
    private func dropUnticked() -> Bool {
        guard let context else { return false }
        var keptAny = false
        for entry in workout.exercises {
            entry.sets.filter { $0.completedAt == nil }.forEach(context.delete)
            if entry.sets.contains(where: { $0.completedAt != nil }) {
                keptAny = true
            } else {
                context.delete(entry)
            }
        }
        return keptAny
    }

    /// Returns whether the workout was kept (vs. dropped for having nothing worth saving) —
    /// the caller uses this to decide whether a post-workout summary has anything to show.
    @discardableResult
    func finish() -> Bool {
        guard let context else { return false }
        // A Kineto session that recorded pain is kept even with nothing ticked: stopping early
        // because it hurt is the most important thing it captured.
        let keep = dropUnticked() || workout.hasPainRecorded
        if keep {
            workout.endedAt = .now
        } else {
            context.delete(workout)
        }
        restTimer.skip()
        try? context.save()
        LiveWorkoutActivity.sync()
        // Gym only: a Kineto streak would conflate back-care with lifting consistency.
        if keep, workout.section == .gym { TrainingSnapshotSync.sync(context: context) }
        return keep
    }

    func saveEdits() {
        _ = dropUnticked()
        try? context?.save()
    }

    func discard() {
        restTimer.skip()
        context?.delete(workout)
        try? context?.save()
        LiveWorkoutActivity.sync()
    }

    func syncLockScreen() {
        if !isHistory { LiveWorkoutActivity.sync() }
    }
}
