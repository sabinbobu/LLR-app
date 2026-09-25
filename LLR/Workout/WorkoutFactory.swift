import Foundation
import SwiftData

enum WorkoutFactory {
    /// A past-workout log is created up front and autosaved, so one interrupted before Save (app
    /// killed) would linger as an empty entry in history. Same rule as Finish: nothing ticked, no
    /// workout — unless it's a Kineto check-in that recorded pain: stopping early because it hurt
    /// is the most important thing that session captured.
    static func removeEmptyHistory(in context: ModelContext) {
        let finished = (try? context.fetch(FetchDescriptor<Workout>(predicate: #Predicate { $0.endedAt != nil }))) ?? []
        for workout in finished where workout.completedSets.isEmpty && !workout.hasPainRecorded {
            context.delete(workout)
        }
        try? context.save()
    }

    /// The workout is persisted immediately so a crash or app kill mid-session loses nothing.
    static func start(copying source: Workout?, in context: ModelContext) -> Workout {
        let workout = Workout()
        workout.section = source?.section ?? .gym
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
                set.durationSeconds = sourceSet.durationSeconds
                context.insert(set)
                entry.sets.append(set)
            }
        }
        try? context.save()
        return workout
    }

    /// One exercise of whatever plan a workout starts from: a saved routine or a library day.
    struct PlannedExercise {
        let exercise: Exercise
        let restSeconds: Int?
        let sets: [PlannedSet]
    }

    static func start(routine: Routine, in context: ModelContext) -> Workout {
        let plan = routine.orderedExercises.compactMap { entry in
            entry.exercise.map { exercise in
                PlannedExercise(
                    exercise: exercise,
                    restSeconds: entry.restSeconds,
                    sets: entry.orderedSets.map {
                        PlannedSet(weightKg: $0.weightKg, reps: $0.reps, kind: $0.kind, durationSeconds: $0.durationSeconds)
                    }
                )
            }
        }
        return start(plan, named: routine.name, section: routine.section, in: context)
    }

    /// A Kineto session's pain check-in, recorded before the first set exists. Back and leg are
    /// scored separately, matching the check-out fields.
    static func start(routine: Routine, backPainBefore: Int?, legPainBefore: Int?, in context: ModelContext) -> Workout {
        let workout = start(routine: routine, in: context)
        workout.backPainBefore = backPainBefore
        workout.legPainBefore = legPainBefore
        try? context.save()
        return workout
    }

    /// A planned weight/reps is used as-is; a blank one falls back to this session's progression
    /// target (or last session's value when no rep range is set), same rule as mid-workout
    /// prefill — "leave it blank to workout on the go". The workout takes the plan's name so
    /// history reads "Push Day" rather than "Evening Workout".
    static func start(_ plan: [PlannedExercise], named name: String, section: WorkoutSection = .gym, in context: ModelContext) -> Workout {
        let workout = Workout()
        workout.name = name
        workout.section = section
        context.insert(workout)
        for (order, planned) in plan.enumerated() {
            let exercise = planned.exercise
            let entry = WorkoutExercise(order: order)
            context.insert(entry)
            entry.exercise = exercise
            workout.exercises.append(entry)
            // Only a gym plan's rest becomes the exercise's shared default; a Kineto routine's
            // rest must never leak into the same exercise's gym rest timer.
            if let restSeconds = planned.restSeconds, section == .gym {
                exercise.restSeconds = restSeconds
            }

            let previous = PreviousPerformance.latestSets(in: exercise.sessions(excluding: workout, section: section))
            let count = max(planned.sets.count, 1)
            for index in 0..<count {
                let plan = index < planned.sets.count ? planned.sets[index] : nil
                let fallback = exercise.progressionPrefill(index: index, previous: previous, currentLast: nil)
                let set = SetEntry(
                    order: index,
                    weightKg: plan?.weightKg ?? fallback?.weightKg ?? 0,
                    reps: plan?.reps ?? fallback?.reps ?? 0
                )
                set.kind = plan?.kind ?? fallback?.kind ?? .normal
                set.durationSeconds = plan?.durationSeconds ?? fallback?.durationSeconds
                context.insert(set)
                entry.sets.append(set)
            }
        }
        try? context.save()
        return workout
    }
}
