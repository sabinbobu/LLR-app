import XCTest
@testable import LLR

final class EquipmentTests: XCTestCase {
    func testEmptyEquipmentReadsAsNone() {
        XCTAssertEqual(Equipment.label([]), "None")
        XCTAssertEqual(Equipment.label(["Barbell"]), "Barbell")
    }

    func testOptionsAreDeduplicatedSortedWithNoneLast() {
        let options = Equipment.options(in: [["Machine"], [], ["Barbell"], ["Machine"], ["Dumbbell"]])
        XCTAssertEqual(options, ["Barbell", "Dumbbell", "Machine", "None"])
    }

    func testNoneFilterMatchesOnlyExercisesWithoutEquipment() {
        XCTAssertTrue(Equipment.matches([], filter: "None"))
        XCTAssertFalse(Equipment.matches(["Barbell"], filter: "None"))
        XCTAssertTrue(Equipment.matches(["Barbell"], filter: "Barbell"))
        XCTAssertFalse(Equipment.matches([], filter: "Barbell"))
    }

    func testDetailOmitsMissingEquipment() {
        XCTAssertEqual(Equipment.detail(muscle: "Chest", equipment: ["Barbell"]), "Chest · Barbell")
        XCTAssertEqual(Equipment.detail(muscle: "Cardio", equipment: []), "Cardio")
    }
}
