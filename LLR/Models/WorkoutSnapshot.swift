import Foundation
import SwiftData

/// A value copy of one workout, so Cancel can put it back exactly as it was. Edits happen in the
/// main context because other contexts' saves don't reliably reach it (screens would show stale
/// sets); undoing the whole context instead would also revert whatever the live workout logged
/// meanwhile, e.g. a set completed from the Lock Screen.
struct WorkoutSnapshot: Equatable {
    struct SetCopy: Equatable {
        let order: Int
        let weightKg: Double
        let reps: Int
        let kindRaw: String
        let durationSeconds: Int?
        let completedAt: Date?
        let rir: Double?
    }

    struct EntryCopy: Equatable {
        let exercise: Exercise?
        let order: Int
        let sets: [SetCopy]

        static func == (lhs: EntryCopy, rhs: EntryCopy) -> Bool {
            lhs.exercise?.persistentModelID == rhs.exercise?.persistentModelID
                && lhs.order == rhs.order && lhs.sets == rhs.sets
        }
    }

    let name: String
    let notes: String
    let startedAt: Date
    let endedAt: Date?
    let entries: [EntryCopy]

    @MainActor
    init(_ workout: Workout) {
        name = workout.name
        notes = workout.notes
        startedAt = workout.startedAt
        endedAt = workout.endedAt
        entries = workout.orderedExercises.map { entry in
            EntryCopy(exercise: entry.exercise, order: entry.order, sets: entry.orderedSets.map {
                SetCopy(
                    order: $0.order, weightKg: $0.weightKg, reps: $0.reps, kindRaw: $0.kindRaw,
                    durationSeconds: $0.durationSeconds, completedAt: $0.completedAt, rir: $0.rir
                )
            })
        }
    }

    @MainActor
    func restore(into workout: Workout, in context: ModelContext) {
        guard WorkoutSnapshot(workout) != self else { return }
        workout.name = name
        workout.notes = notes
        workout.startedAt = startedAt
        workout.endedAt = endedAt
        let current = workout.exercises
        workout.exercises.removeAll()
        current.forEach(context.delete)
        for copy in entries {
            let entry = WorkoutExercise(order: copy.order)
            context.insert(entry)
            entry.exercise = copy.exercise
            workout.exercises.append(entry)
            for setCopy in copy.sets {
                let set = SetEntry(order: setCopy.order, weightKg: setCopy.weightKg, reps: setCopy.reps)
                set.kindRaw = setCopy.kindRaw
                set.durationSeconds = setCopy.durationSeconds
                set.completedAt = setCopy.completedAt
                set.rir = setCopy.rir
                context.insert(set)
                entry.sets.append(set)
            }
        }
    }
}
