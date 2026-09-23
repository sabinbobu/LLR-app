import Foundation
import SwiftData

enum WorkoutFactory {
    /// The workout is persisted immediately so a crash or app kill mid-session loses nothing.
    static func start(copying source: Workout?, in context: ModelContext) -> Workout {
        let workout = Workout()
        context.insert(workout)
        for (index, sourceEntry) in (source?.orderedExercises ?? []).enumerated() {
            guard let exercise = sourceEntry.exercise else { continue }
            let entry = WorkoutExercise(order: index)
            context.insert(entry)
            entry.exercise = exercise
            workout.exercises.append(entry)
            for (setIndex, sourceSet) in sourceEntry.completedSets.enumerated() {
                let set = SetEntry(order: setIndex, weightKg: sourceSet.weightKg, reps: sourceSet.reps)
                set.kind = sourceSet.kind
                context.insert(set)
                entry.sets.append(set)
            }
        }
        try? context.save()
        return workout
    }
}
