import Foundation

/// What the Lock Screen shows, derived from plain values so it's testable without SwiftData or ActivityKit.
enum LiveWorkoutContent {
    struct Exercise {
        let name: String
        let sets: [SetValue]
        let completed: [Bool]
        var supersetGroup: Int? = nil
    }

    typealias Position = Superset.Position

    /// The first unticked set in workout order — the one a lifter at the rack is about to do —
    /// alternating through a superset.
    static func next(in exercises: [Exercise]) -> Position? {
        Superset.next(in: exercises.map { Superset.Member(group: $0.supersetGroup, completed: $0.completed) })
    }

    static func state(
        _ exercises: [Exercise],
        unit: WeightUnit,
        restStartedAt: Date?,
        restEndsAt: Date?
    ) -> WorkoutActivityAttributes.ContentState {
        let total = exercises.reduce(0) { $0 + $1.sets.count }
        let done = exercises.reduce(0) { $0 + $1.completed.filter { $0 }.count }
        var state = WorkoutActivityAttributes.ContentState(
            exerciseName: nil, setLabel: "All sets done", target: "Finish in LLR",
            canComplete: false, completedSets: done, totalSets: total,
            restStartedAt: restStartedAt, restEndsAt: restEndsAt
        )
        guard let position = next(in: exercises) else { return state }
        let exercise = exercises[position.exercise]
        let set = exercise.sets[position.set]
        state.exerciseName = exercise.name
        state.setLabel = setLabel(set.kind, position: position.set + 1, of: exercise.sets.count)
        state.target = target(set, unit: unit)
        state.canComplete = set.reps > 0
        return state
    }

    static func setLabel(_ kind: SetKind, position: Int, of count: Int) -> String {
        let base = "Set \(position) of \(count)"
        return switch kind {
        case .normal: base
        case .warmup: "\(base) · Warm-up"
        case .drop: "\(base) · Drop"
        case .failure: "\(base) · Failure"
        }
    }

    static func target(_ set: SetValue, unit: WeightUnit) -> String {
        guard set.reps > 0 else { return "Enter reps in LLR" }
        if let seconds = set.durationSeconds { return "\(set.reps) × \(seconds) s" }
        guard set.weightKg > 0 else { return "\(set.reps) reps" }
        return "\(unit.format(kg: set.weightKg)) \(unit.rawValue) × \(set.reps)"
    }
}
