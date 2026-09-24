import XCTest
@testable import LLR

final class LiveWorkoutContentTests: XCTestCase {
    private func exercise(_ name: String, _ sets: [(Double, Int, SetKind)], done: [Bool]) -> LiveWorkoutContent.Exercise {
        .init(name: name, sets: sets.map { SetValue(weightKg: $0.0, reps: $0.1, kind: $0.2) }, completed: done)
    }

    func testNextIsFirstUntickedSetInWorkoutOrder() {
        let workout = [
            exercise("Squat", [(60, 5, .warmup), (100, 5, .normal)], done: [true, true]),
            exercise("Bench", [(80, 8, .normal), (80, 8, .normal), (80, 8, .normal)], done: [true, false, false]),
        ]
        XCTAssertEqual(LiveWorkoutContent.next(in: workout), .init(exercise: 1, set: 1))
    }

    func testStateDescribesTheNextSetAndCounts() {
        let workout = [exercise("Bench Press (Barbell)", [(40, 10, .warmup), (80, 8, .normal)], done: [true, false])]
        let end = Date.now.addingTimeInterval(90)
        let state = LiveWorkoutContent.state(workout, unit: .kg, restStartedAt: .now, restEndsAt: end)
        XCTAssertEqual(state.exerciseName, "Bench Press (Barbell)")
        XCTAssertEqual(state.setLabel, "Set 2 of 2")
        XCTAssertEqual(state.target, "80 kg × 8")
        XCTAssertTrue(state.canComplete)
        XCTAssertEqual(state.completedSets, 1)
        XCTAssertEqual(state.totalSets, 2)
        XCTAssertTrue(state.isResting)
    }

    func testWarmupLabelAndPoundsTarget() {
        let workout = [exercise("Squat (Barbell)", [(60, 5, .warmup)], done: [false])]
        let state = LiveWorkoutContent.state(workout, unit: .lbs, restStartedAt: nil, restEndsAt: nil)
        XCTAssertEqual(state.setLabel, "Set 1 of 1 · Warm-up")
        XCTAssertEqual(state.target, "132.3 lbs × 5")
        XCTAssertFalse(state.isResting)
    }

    func testSetWithoutRepsCantBeLoggedBlind() {
        let state = LiveWorkoutContent.state([exercise("Pull Up", [(0, 0, .normal)], done: [false])], unit: .kg, restStartedAt: nil, restEndsAt: nil)
        XCTAssertFalse(state.canComplete)
        XCTAssertEqual(state.target, "Enter reps in LLR")
    }

    func testBodyweightTargetShowsRepsOnly() {
        XCTAssertEqual(LiveWorkoutContent.target(SetValue(weightKg: 0, reps: 12), unit: .kg), "12 reps")
    }

    func testAllDonePointsToFinish() {
        let state = LiveWorkoutContent.state([exercise("Row", [(60, 10, .normal)], done: [true])], unit: .kg, restStartedAt: nil, restEndsAt: nil)
        XCTAssertNil(state.exerciseName)
        XCTAssertFalse(state.canComplete)
        XCTAssertEqual(state.completedSets, 1)
    }

    func testPastRestIsNotResting() {
        let state = LiveWorkoutContent.state([], unit: .kg, restStartedAt: .now.addingTimeInterval(-120), restEndsAt: .now.addingTimeInterval(-30))
        XCTAssertFalse(state.isResting)
    }
}
