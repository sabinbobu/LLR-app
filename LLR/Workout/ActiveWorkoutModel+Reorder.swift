import Foundation

extension ActiveWorkoutModel {
    /// Swaps the exercise on a card for this workout only. Sets already ticked happened on the old
    /// exercise and stay there; what was left to do carries on as the new one, aimed at its own history.
    func swap(_ entry: WorkoutExercise, to exercise: Exercise) {
        guard let context = workout.modelContext, entry.exercise !== exercise else { return }
        let unticked = entry.sets.filter { $0.completedAt == nil }
        let target: WorkoutExercise
        if unticked.count == entry.sets.count {
            target = entry
            entry.exercise = exercise
        } else {
            for later in workout.exercises where later.order > entry.order { later.order += 1 }
            target = WorkoutExercise(order: entry.order + 1)
            target.supersetGroup = entry.supersetGroup
            context.insert(target)
            target.exercise = exercise
            workout.exercises.append(target)
        }
        for set in unticked {
            entry.sets.removeAll { $0 === set }
            context.delete(set)
        }
        let history = history(for: exercise)
        for index in 0..<max(unticked.count, 1) {
            appendSet(to: target, prefill: exercise.progressionPrefill(index: index, history: history, currentLast: nil))
        }
        syncLockScreen()
    }

    func canMove(_ entry: WorkoutExercise, by offset: Int) -> Bool {
        let entries = workout.orderedExercises
        guard let index = entries.firstIndex(where: { $0 === entry }) else { return false }
        return entries.indices.contains(index + offset)
    }

    func move(_ entry: WorkoutExercise, by offset: Int) {
        let entries = workout.orderedExercises
        guard let index = entries.firstIndex(where: { $0 === entry }), entries.indices.contains(index + offset) else { return }
        let other = entries[index + offset]
        (entry.order, other.order) = (other.order, entry.order)
        syncLockScreen()
    }

    func remove(_ entry: WorkoutExercise) {
        let copy = WorkoutSnapshot.EntryCopy(entry)
        let name = entry.exercise?.name ?? "Exercise"
        workout.exercises.removeAll { $0 === entry }
        workout.modelContext?.delete(entry)
        removal = UndoableRemoval(title: "\(name) removed") { [weak self] in
            guard let self, !workout.isDeleted, let context = workout.modelContext else { return }
            copy.insert(into: workout, in: context)
            syncLockScreen()
        }
        syncLockScreen()
    }
}
