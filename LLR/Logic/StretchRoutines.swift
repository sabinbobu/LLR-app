import Foundation
import SwiftData

/// A short cool-down matched to a push, pull or legs session. Every set is a timed hold tagged
/// `.warmup`, so a cool-down adds nothing to volume, PRs or Weekly Volume and starts no rest.
/// Sources and the dosing rationale: docs/stretch-routine-research.md.
enum StretchRoutines {
    static let holdSeconds = 30
    static let cooldownSuffix = "Cooldown"

    struct Move: Equatable {
        let exercise: String
        /// Two sets = left and right.
        let sets: Int
    }

    static func moves(for category: SessionCategory) -> [Move]? {
        switch category {
        case .push:
            [Move(exercise: "Chest Doorway Stretch", sets: 1), Move(exercise: "Cross-Body Shoulder Stretch", sets: 2),
             Move(exercise: "Overhead Triceps Stretch", sets: 2), Move(exercise: "Wrist Flexor Stretch", sets: 2)]
        case .pull:
            [Move(exercise: "Lat Side Reach Stretch", sets: 2), Move(exercise: "Biceps Wall Stretch", sets: 2),
             Move(exercise: "Child's Pose Stretch", sets: 1), Move(exercise: "Upper Trap Neck Stretch", sets: 2)]
        case .legs:
            [Move(exercise: "Standing Quad Stretch", sets: 2), Move(exercise: "Seated Hamstring Stretch", sets: 2),
             Move(exercise: "Standing Calf Stretch", sets: 2), Move(exercise: "Kneeling Hip Flexor Stretch", sets: 2),
             Move(exercise: "Figure-Four Glute Stretch", sets: 2)]
        case .yoga, .none:
            nil
        }
    }

    static func offersCooldown(after workout: Workout) -> Bool {
        // A cool-down keeps its session's category, so it must not offer a cool-down of its own.
        workout.section == .gym && moves(for: workout.category) != nil && !workout.name.hasSuffix(cooldownSuffix)
    }

    /// nil when the category has no cool-down. Exercises missing from the library are skipped.
    static func plan(for category: SessionCategory, exercises: [String: Exercise]) -> [WorkoutFactory.PlannedExercise]? {
        guard let moves = moves(for: category) else { return nil }
        let planned = moves.compactMap { move -> WorkoutFactory.PlannedExercise? in
            guard let exercise = exercises[move.exercise] else { return nil }
            let set = PlannedSet(weightKg: nil, reps: 1, kind: .warmup, durationSeconds: holdSeconds)
            return WorkoutFactory.PlannedExercise(exercise: exercise, restSeconds: nil, sets: Array(repeating: set, count: move.sets))
        }
        return planned.isEmpty ? nil : planned
    }
}

extension StretchRoutines {
    /// A separate workout, not an append: adding to a finished workout would rewrite its recorded
    /// duration. It is only created when the user taps the offer, so declining leaves nothing behind.
    @MainActor
    static func startCooldown(after workout: Workout, in context: ModelContext) -> Workout? {
        guard offersCooldown(after: workout),
              let plan = plan(for: workout.category, exercises: RoutineLibrary.exercisesByName(in: context))
        else { return nil }
        return WorkoutFactory.start(plan, named: "\(workout.category.title) \(cooldownSuffix)", category: workout.category, in: context)
    }
}
