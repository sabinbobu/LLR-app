import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ActiveWorkoutModel {
    let workout: Workout
    let restTimer = RestTimer.shared
    /// Editing a finished workout: no rest timer, and the Lock Screen is never touched —
    /// it only ever mirrors the workout in progress.
    let isHistory: Bool

    init(workout: Workout, isHistory: Bool = false) {
        self.workout = workout
        self.isHistory = isHistory
    }

    private var context: ModelContext? { workout.modelContext }

    var defaultRestSeconds: Int {
        UserDefaults.standard.object(forKey: StorageKey.restSeconds) as? Int ?? RestDuration.defaultSeconds
    }

    func previousSets(for exercise: Exercise) -> [SetValue] {
        PreviousPerformance.latestSets(in: exercise.sessions(excluding: workout, section: workout.section))
    }

    func add(_ exercise: Exercise) {
        guard let context else { return }
        let entry = WorkoutExercise(order: (workout.exercises.map(\.order).max() ?? -1) + 1)
        context.insert(entry)
        entry.exercise = exercise
        workout.exercises.append(entry)
        // Mirror last session's set count so a repeat day is pure check-tapping.
        let previous = previousSets(for: exercise)
        for index in 0..<max(previous.count, 1) {
            appendSet(to: entry, prefill: exercise.progressionPrefill(index: index, previous: previous, currentLast: nil))
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
        let previous = entry.exercise.map(previousSets(for:)) ?? []
        let prefill = entry.exercise?.progressionPrefill(
            index: entry.sets.count,
            previous: previous,
            currentLast: entry.orderedSets.last?.value
        ) ?? PreviousPerformance.prefill(index: entry.sets.count, previous: previous, currentLast: entry.orderedSets.last?.value)
        appendSet(to: entry, prefill: prefill)
        syncLockScreen()
    }

    private func appendSet(to entry: WorkoutExercise, prefill: SetValue?) {
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

    /// Re-targets only unticked sets: logged sets are history, whatever the range says now.
    func setRepRange(_ range: ClosedRange<Int>?, for entry: WorkoutExercise) {
        guard let exercise = entry.exercise else { return }
        exercise.repRange = range
        let previous = previousSets(for: exercise)
        for (index, set) in entry.orderedSets.enumerated() where set.completedAt == nil {
            guard let target = exercise.progressionPrefill(index: index, previous: previous, currentLast: nil) else { continue }
            set.weightKg = target.weightKg
            set.reps = target.reps
        }
        syncLockScreen()
    }

    /// Returns false when the set can't be completed (no reps), so the row can signal it.
    @discardableResult
    func toggle(_ set: SetEntry) -> Bool {
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
        if let seconds = RestDuration.resolve(override: exercise?.restSeconds, defaultSeconds: defaultRestSeconds) {
            restTimer.start(seconds: seconds, exerciseName: exercise?.name)
        } else {
            restTimer.skip()
        }
        return true
    }

    func delete(_ set: SetEntry) {
        context?.delete(set)
        syncLockScreen()
    }

    func remove(_ entry: WorkoutExercise) {
        context?.delete(entry)
        syncLockScreen()
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

    func finish() {
        guard let context else { return }
        // A Kineto session that recorded pain is kept even with nothing ticked: stopping early
        // because it hurt is the most important thing it captured.
        if dropUnticked() || workout.hasPainRecorded {
            workout.endedAt = .now
        } else {
            context.delete(workout)
        }
        restTimer.skip()
        try? context.save()
        LiveWorkoutActivity.sync()
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

    private func syncLockScreen() {
        if !isHistory { LiveWorkoutActivity.sync() }
    }
}
