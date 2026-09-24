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

    /// A planned weight/reps is used as-is; a blank one falls back to this session's progression
    /// target (or last session's value when no rep range is set), same rule as mid-workout
    /// prefill — "leave it blank to workout on the go".
    static func start(routine: Routine, in context: ModelContext) -> Workout {
        let workout = Workout()
        context.insert(workout)
        for routineEntry in routine.orderedExercises {
            guard let exercise = routineEntry.exercise else { continue }
            let entry = WorkoutExercise(order: routineEntry.order)
            context.insert(entry)
            entry.exercise = exercise
            workout.exercises.append(entry)
            if let restSeconds = routineEntry.restSeconds {
                exercise.restSeconds = restSeconds
            }

            let previous = PreviousPerformance.latestSets(in: exercise.sessions(excluding: workout))
            let plans = routineEntry.orderedSets
            let count = max(plans.count, 1)
            for index in 0..<count {
                let plan = index < plans.count ? plans[index] : nil
                let fallback = exercise.progressionPrefill(index: index, previous: previous, currentLast: nil)
                let set = SetEntry(
                    order: index,
                    weightKg: plan?.weightKg ?? fallback?.weightKg ?? 0,
                    reps: plan?.reps ?? fallback?.reps ?? 0
                )
                set.kind = plan?.kind ?? fallback?.kind ?? .normal
                context.insert(set)
                entry.sets.append(set)
            }
        }
        try? context.save()
        return workout
    }
}
