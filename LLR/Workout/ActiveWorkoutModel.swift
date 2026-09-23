import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ActiveWorkoutModel {
    let workout: Workout
    let restTimer = RestTimer()

    init(workout: Workout) {
        self.workout = workout
    }

    private var context: ModelContext? { workout.modelContext }

    private var restSeconds: Int {
        UserDefaults.standard.object(forKey: StorageKey.restSeconds) as? Int ?? 90
    }

    func previousSets(for exercise: Exercise) -> [SetValue] {
        PreviousPerformance.latestSets(in: exercise.sessions(excluding: workout))
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
            appendSet(to: entry, prefill: PreviousPerformance.prefill(index: index, previous: previous, currentLast: nil))
        }
    }

    func addSet(to entry: WorkoutExercise) {
        let previous = entry.exercise.map(previousSets(for:)) ?? []
        let prefill = PreviousPerformance.prefill(
            index: entry.sets.count,
            previous: previous,
            currentLast: entry.orderedSets.last?.value
        )
        appendSet(to: entry, prefill: prefill)
    }

    private func appendSet(to entry: WorkoutExercise, prefill: SetValue?) {
        guard let context else { return }
        let set = SetEntry(
            order: (entry.sets.map(\.order).max() ?? -1) + 1,
            weightKg: prefill?.weightKg ?? 0,
            reps: prefill?.reps ?? 0
        )
        context.insert(set)
        entry.sets.append(set)
    }

    /// Returns false when the set can't be completed (no reps), so the row can signal it.
    @discardableResult
    func toggle(_ set: SetEntry) -> Bool {
        if set.completedAt != nil {
            set.completedAt = nil
            return true
        }
        guard set.reps > 0 else { return false }
        set.completedAt = .now
        restTimer.start(seconds: restSeconds)
        return true
    }

    func delete(_ set: SetEntry) {
        context?.delete(set)
    }

    func remove(_ entry: WorkoutExercise) {
        context?.delete(entry)
    }

    /// Unchecked sets are drafts, not history: drop them so they never pollute previous-value lookups.
    func finish() {
        guard let context else { return }
        var keptAny = false
        for entry in workout.exercises {
            entry.sets.filter { $0.completedAt == nil }.forEach(context.delete)
            if entry.sets.contains(where: { $0.completedAt != nil }) {
                keptAny = true
            } else {
                context.delete(entry)
            }
        }
        if keptAny {
            workout.endedAt = .now
        } else {
            context.delete(workout)
        }
        restTimer.skip()
        try? context.save()
    }

    func discard() {
        restTimer.skip()
        context?.delete(workout)
        try? context?.save()
    }
}
