import Foundation
import SwiftData

enum RoutineFactory {
    /// A finished workout turned into a reusable routine. It keeps the structure (exercises in order,
    /// one plan per completed set with its reps, kind and hold time) and leaves the weight blank, the
    /// same shape as a library routine: starting it prefills weights from the latest session, so
    /// the routine never freezes the numbers of the day it was saved.
    @discardableResult
    static func save(_ workout: Workout, in context: ModelContext) -> Routine {
        let routine = Routine(name: workout.title)
        routine.category = workout.category
        routine.section = workout.section
        context.insert(routine)
        var order = 0
        for entry in workout.orderedExercises {
            // Nothing ticked means it was planned but not done, so it isn't part of what happened.
            guard let exercise = entry.exercise, !entry.completedSets.isEmpty else { continue }
            let item = RoutineExercise(order: order)
            order += 1
            context.insert(item)
            item.exercise = exercise
            item.restSeconds = exercise.restSeconds
            item.supersetGroup = entry.supersetGroup
            routine.exercises.append(item)
            for (index, set) in entry.completedSets.enumerated() {
                let plan = RoutineSetPlan(order: index, reps: set.reps)
                plan.kind = set.kind
                plan.durationSeconds = set.durationSeconds
                context.insert(plan)
                item.sets.append(plan)
            }
        }
        try? context.save()
        return routine
    }
}
