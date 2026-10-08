import SwiftData
import XCTest
@testable import LLR

/// Covers `WorkoutExercise.recoveryEntries`/`Workout.recoveryEntries` (Models.swift) — the glue that
/// turns real logged sets into `MuscleRecovery.Entry`s. `MuscleRecoveryTests` covers the pure math.
@MainActor
final class RecoveryEntriesTests: XCTestCase {
    private var context: ModelContext!
    private var bench: Exercise!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        bench = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")
        bench.secondaryMuscles = ["Triceps", "Shoulders"]
        context.insert(bench)
    }

    private func entryWith(_ sets: [(weightKg: Double, reps: Int, kind: SetKind, completed: Bool)]) -> WorkoutExercise {
        let workout = Workout()
        context.insert(workout)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        workout.exercises.append(entry)
        for (index, spec) in sets.enumerated() {
            let set = SetEntry(order: index, weightKg: spec.weightKg, reps: spec.reps)
            set.kind = spec.kind
            set.completedAt = spec.completed ? .now : nil
            context.insert(set)
            entry.sets.append(set)
        }
        return entry
    }

    func testOnlyCompletedWorkingSetsBecomeRecoveryEntries() {
        let entry = entryWith([
            (80, 8, .normal, true),
            (40, 12, .warmup, true),
            (80, 8, .normal, false),
        ])
        XCTAssertEqual(entry.recoveryEntries.count, 1, "warm-ups and unticked sets never load recovery")
    }

    func testRecoveryEntryCarriesTheExercisesPrimaryAndSecondaryMuscles() throws {
        let entry = entryWith([(80, 8, .normal, true)])
        let recoveryEntry = try XCTUnwrap(entry.recoveryEntries.first)
        XCTAssertEqual(recoveryEntry.muscle, "Chest")
        XCTAssertEqual(recoveryEntry.secondaryMuscles, ["Triceps", "Shoulders"])
        XCTAssertEqual(recoveryEntry.exerciseName, "Bench Press (Barbell)")
    }

    func testRecoveryEntryCarriesTheSetsEffortRating() {
        let entry = entryWith([(80, 8, .normal, true), (80, 8, .normal, true)])
        entry.orderedSets.first?.rir = 1.5
        XCTAssertEqual(entry.recoveryEntries.map(\.rir), [1.5, nil])
    }

    func testWorkoutRecoveryEntriesFlattenAcrossExercises() {
        let workout = Workout()
        context.insert(workout)
        let row = Exercise(name: "Bent Over Row (Barbell)", muscleGroup: "Upper Back")
        context.insert(row)
        for (order, exercise) in [(0, bench!), (1, row)] {
            let entry = WorkoutExercise(order: order)
            context.insert(entry)
            entry.exercise = exercise
            workout.exercises.append(entry)
            let set = SetEntry(order: 0, weightKg: 60, reps: 10)
            set.completedAt = .now
            context.insert(set)
            entry.sets.append(set)
        }
        XCTAssertEqual(workout.recoveryEntries.count, 2)
    }
}
