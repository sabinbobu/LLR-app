import Foundation

/// The last thing removed from the workout, kept so one tap can put it back.
struct UndoableRemoval: Identifiable {
    let id = UUID()
    let title: String
    let restore: () -> Void
}

extension ActiveWorkoutModel {
    func delete(_ set: SetEntry) {
        let copy = WorkoutSnapshot.SetCopy(set)
        let entry = set.workoutExercise
        entry?.sets.removeAll { $0 === set }
        workout.modelContext?.delete(set)
        removal = UndoableRemoval(title: "Set deleted") { [weak self] in
            // The exercise may have been removed since; a set with nowhere to go stays gone.
            guard let entry, !entry.isDeleted, let context = entry.modelContext else { return }
            let restored = copy.make()
            context.insert(restored)
            entry.sets.append(restored)
            self?.syncLockScreen()
        }
        syncLockScreen()
    }

    func undoRemoval() {
        removal?.restore()
        removal = nil
    }

    /// A fresh, unticked copy right after the original: same load, reps and kind, no effort yet.
    func duplicate(_ set: SetEntry) {
        guard let context = workout.modelContext, let entry = set.workoutExercise else { return }
        for later in entry.sets where later.order > set.order { later.order += 1 }
        let copy = SetEntry(order: set.order + 1, weightKg: set.weightKg, reps: set.reps)
        copy.kind = set.kind
        copy.durationSeconds = set.durationSeconds
        context.insert(copy)
        entry.sets.append(copy)
        syncLockScreen()
    }
}
