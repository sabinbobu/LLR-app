import Foundation

/// A snapshot of a finished workout for the post-workout summary and its share card: totals, which
/// muscles it worked, and every record it set. Pure and reusable, no SwiftUI.
struct WorkoutRecap {
    struct RecordLine: Identifiable, Equatable {
        var id: String { exerciseName + kind.rawValue }
        let exerciseName: String
        let kind: PersonalRecords.Kind
        let valueKg: Double
    }

    let volumeKg: Double
    let duration: TimeInterval
    let setCount: Int
    let records: [RecordLine]
    let primaryMuscles: Set<MuscleGroup>
    /// Never overlaps `primaryMuscles` — a muscle already badged as primary doesn't need the lighter tint too.
    let secondaryMuscles: Set<MuscleGroup>

    init(_ workout: Workout) {
        volumeKg = workout.volumeKg
        duration = workout.duration
        setCount = workout.completedSets.count

        var lines: [RecordLine] = []
        var primaries: Set<MuscleGroup> = []
        var secondaries: Set<MuscleGroup> = []
        for entry in workout.orderedExercises {
            guard let exercise = entry.exercise else { continue }
            if let group = MuscleGroup(rawValue: exercise.muscleGroup), group.isTrainable {
                primaries.insert(group)
            }
            for raw in exercise.secondaryMuscles {
                if let group = MuscleGroup(rawValue: raw), group.isTrainable { secondaries.insert(group) }
            }
            let sets = entry.orderedSets
            let recordKinds = entry.recordKinds()
            for (index, set) in sets.enumerated() where set.completedAt != nil {
                for kind in recordKinds[index].sorted() {
                    lines.append(RecordLine(exerciseName: exercise.name, kind: kind, valueKg: PersonalRecords.metric(kind, set.value)))
                }
            }
        }
        records = lines
        primaryMuscles = primaries
        secondaryMuscles = secondaries.subtracting(primaries)
    }
}
