import SwiftData
import XCTest
@testable import LLR

@MainActor
final class FinishCheckTests: XCTestCase {
    func testNoSetsTickedIsNothingLogged() {
        XCTAssertEqual(FinishCheck(ticked: 0, total: 15), .nothingLogged)
    }

    func testAnEmptyWorkoutIsNothingLogged() {
        XCTAssertEqual(FinishCheck(ticked: 0, total: 0), .nothingLogged)
    }

    func testSomeUntickedAsksFirstAndCountsThem() {
        XCTAssertEqual(FinishCheck(ticked: 1, total: 15), .dropsUnticked(14))
    }

    func testAllTickedFinishesStraightAway() {
        XCTAssertEqual(FinishCheck(ticked: 15, total: 15), .ready)
    }

    func testOnlyTheDropCaseWarns() {
        XCTAssertEqual(FinishCheck.dropsUnticked(14).warning, "14 unticked sets will be removed.")
        XCTAssertEqual(FinishCheck.dropsUnticked(1).warning, "1 unticked set will be removed.")
        XCTAssertNil(FinishCheck.ready.warning)
        XCTAssertNil(FinishCheck.nothingLogged.warning)
    }

    func testCountsSetsAcrossAllExercisesOfAWorkout() throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let workout = Workout()
        context.insert(workout)
        for order in 0..<2 {
            let entry = WorkoutExercise(order: order)
            context.insert(entry)
            workout.exercises.append(entry)
            for index in 0..<3 {
                let set = SetEntry(order: index, weightKg: 60, reps: 8)
                context.insert(set)
                entry.sets.append(set)
            }
        }
        XCTAssertEqual(FinishCheck(workout), .nothingLogged)
        workout.exercises[0].sets[0].completedAt = .now
        XCTAssertEqual(FinishCheck(workout), .dropsUnticked(5))
    }
}
