import XCTest
@testable import LLR

final class SwapFilterTests: XCTestCase {
    func testSwapOpensFilteredToTheReplacedExercisesMuscle() {
        XCTAssertEqual(SwapFilter.muscle(for: Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")), "Chest")
    }

    func testBroadOrMissingGroupsOpenUnfiltered() {
        XCTAssertNil(SwapFilter.muscle(for: Exercise(name: "Burpee", muscleGroup: "Full Body")))
        XCTAssertNil(SwapFilter.muscle(for: Exercise(name: "Stretching", muscleGroup: "Other")))
        XCTAssertNil(SwapFilter.muscle(for: Exercise(name: "Cycling", muscleGroup: "Cardio")))
        XCTAssertNil(SwapFilter.muscle(for: Exercise(name: "x", muscleGroup: "")))
        XCTAssertNil(SwapFilter.muscle(for: nil))
    }
}
