import SwiftData
import XCTest
@testable import LLR

@MainActor
final class WorkoutRecapTests: XCTestCase {
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

    func testAnEmptyWorkoutHasZeroedTotalsAndNoRecords() {
        let workout = Workout()
        context.insert(workout)
        let recap = WorkoutRecap(workout)
        XCTAssertEqual(recap.volumeKg, 0)
        XCTAssertEqual(recap.setCount, 0)
        XCTAssertTrue(recap.records.isEmpty)
        XCTAssertTrue(recap.primaryMuscles.isEmpty)
        XCTAssertTrue(recap.secondaryMuscles.isEmpty)
    }

    func testPrimaryAndSecondaryMusclesNeverOverlap() {
        // Row's secondary (Biceps, Traps, Lower Back) never touches Bench's primary (Chest); this
        // just wires two exercises together so the union/subtraction logic runs on real data.
        let row = Exercise(name: "Bent Over Row (Barbell)", muscleGroup: "Upper Back")
        row.secondaryMuscles = ["Chest"] // shares Chest with bench's primary
        context.insert(row)
        let workout = Workout()
        context.insert(workout)
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

        let recap = WorkoutRecap(workout)
        XCTAssertTrue(recap.primaryMuscles.contains(.chest))
        XCTAssertTrue(recap.primaryMuscles.contains(.upperBack))
        XCTAssertFalse(recap.secondaryMuscles.contains(.chest), "Chest is already primary via bench")
        XCTAssertTrue(recap.secondaryMuscles.contains(.triceps))
        XCTAssertTrue(recap.secondaryMuscles.contains(.shoulders))
    }

    func testRecordLinesComeFromEveryCompletedSetThatSetOne() {
        let workout = Workout(startedAt: .now.addingTimeInterval(-7 * 86_400))
        workout.endedAt = workout.startedAt.addingTimeInterval(3600)
        context.insert(workout)
        let pastEntry = WorkoutExercise(order: 0)
        context.insert(pastEntry)
        pastEntry.exercise = bench
        workout.exercises.append(pastEntry)
        let pastSet = SetEntry(order: 0, weightKg: 80, reps: 8)
        pastSet.completedAt = workout.startedAt
        context.insert(pastSet)
        pastEntry.sets.append(pastSet)

        let today = Workout()
        context.insert(today)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        today.exercises.append(entry)
        let set = SetEntry(order: 0, weightKg: 85, reps: 8)
        set.completedAt = .now
        context.insert(set)
        entry.sets.append(set)

        let recap = WorkoutRecap(today)
        XCTAssertFalse(recap.records.isEmpty)
        XCTAssertTrue(recap.records.allSatisfy { $0.exerciseName == "Bench Press (Barbell)" })
        XCTAssertTrue(recap.records.contains { $0.kind == .weight })
    }

    func testVolumeAndSetCountOnlyCountCompletedSets() {
        let workout = Workout()
        context.insert(workout)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        workout.exercises.append(entry)
        let done = SetEntry(order: 0, weightKg: 80, reps: 8)
        done.completedAt = .now
        let undone = SetEntry(order: 1, weightKg: 80, reps: 8)
        context.insert(done)
        context.insert(undone)
        entry.sets.append(contentsOf: [done, undone])

        let recap = WorkoutRecap(workout)
        XCTAssertEqual(recap.setCount, 1)
        XCTAssertEqual(recap.volumeKg, 80 * 8)
    }
}
