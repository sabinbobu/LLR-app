import SwiftData
import XCTest
@testable import LLR

@MainActor
final class TimedWarmupTests: XCTestCase {
    private var context: ModelContext!
    private var bike: Exercise!
    private var bench: Exercise!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        bike = Exercise(name: "Easy Cardio Warm-up", muscleGroup: "Cardio")
        bench = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")
        context.insert(bike)
        context.insert(bench)
        RestTimer.shared.skip()
    }

    func testCardioFirstInWorkoutIsATimedWarmupSet() {
        let value = TimedWarmup.prefill(muscleGroup: "Cardio", name: "Cycling", history: [], isFirstInWorkout: true)
        XCTAssertEqual(value, SetValue(weightKg: 0, reps: 1, kind: .warmup, durationSeconds: 300))
    }

    func testCardioLaterInWorkoutIsTimedButNotAWarmup() {
        let value = TimedWarmup.prefill(muscleGroup: "Cardio", name: "Cycling", history: [], isFirstInWorkout: false)
        XCTAssertEqual(value?.kind, .normal)
        XCTAssertEqual(value?.durationSeconds, 300)
    }

    func testLiftsAndOldWeightRepsCardioHistoryAreLeftAlone() {
        XCTAssertNil(TimedWarmup.prefill(muscleGroup: "Chest", name: "Bench Press (Barbell)", history: [], isFirstInWorkout: true))
        let old = [Session(date: .now, sets: [SetValue(weightKg: 0, reps: 20)])]
        XCTAssertNil(TimedWarmup.prefill(muscleGroup: "Cardio", name: "Cycling", history: old, isFirstInWorkout: true))
    }

    func testRememberedDurationIsReused() {
        let past = [Session(date: .now, sets: [SetValue(weightKg: 0, reps: 1, kind: .warmup, durationSeconds: 600)])]
        XCTAssertEqual(TimedWarmup.prefill(muscleGroup: "Cardio", name: "Cycling", history: past, isFirstInWorkout: true)?.durationSeconds, 600)
    }

    func testTickingATimedWarmupStartsNoRestAndAddsNoVolume() throws {
        let workout = Workout(startedAt: .now)
        context.insert(workout)
        let model = ActiveWorkoutModel(workout: workout)
        model.add(bike)
        let entry = try XCTUnwrap(workout.orderedExercises.first)
        let set = try XCTUnwrap(entry.orderedSets.first)
        XCTAssertEqual(set.kind, .warmup)
        XCTAssertTrue(entry.isDurationBased)

        XCTAssertTrue(model.toggle(set))
        XCTAssertFalse(RestTimer.shared.isRunning)
        XCTAssertEqual(workout.volumeKg, 0)
    }

    func testOrdinaryLiftStillStartsItsRest() throws {
        let workout = Workout(startedAt: .now)
        context.insert(workout)
        let model = ActiveWorkoutModel(workout: workout)
        model.add(bench)
        let set = try XCTUnwrap(workout.orderedExercises.first?.orderedSets.first)
        set.weightKg = 60
        set.reps = 5
        XCTAssertTrue(model.toggle(set))
        XCTAssertTrue(RestTimer.shared.isRunning)
        RestTimer.shared.skip()
    }
}
