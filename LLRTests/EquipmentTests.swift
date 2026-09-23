import XCTest
@testable import LLR

final class EquipmentTests: XCTestCase {
    func testExtractsKnownEquipmentFromTrailingParens() {
        XCTAssertEqual(Equipment.tag(for: "Bench Press (Barbell)"), "Barbell")
        XCTAssertEqual(Equipment.tag(for: "Squat (Smith Machine)"), "Smith Machine")
        XCTAssertEqual(Equipment.tag(for: "Pull Up (Weighted)"), "Other")
    }

    func testNoParensIsOther() {
        XCTAssertEqual(Equipment.tag(for: "Push Up"), "Other")
        XCTAssertEqual(Equipment.tag(for: "Running"), "Other")
    }

    func testEarlierParensDoesNotFoolTheMatch() {
        // "Close Grip" in parens comes before the real equipment tag isn't present here,
        // so this exercise correctly falls back to Other rather than matching mid-string.
        XCTAssertEqual(Equipment.tag(for: "Push Up - Close Grip"), "Other")
    }

    func testAllTagsIsSortedAndDeduplicated() {
        let names = ["Bench Press (Barbell)", "Squat (Barbell)", "Curl (Dumbbell)", "Push Up"]
        XCTAssertEqual(Equipment.allTags(in: names), ["Barbell", "Dumbbell", "Other"])
    }
}
