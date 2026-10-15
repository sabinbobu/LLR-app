import XCTest
@testable import LLR

final class NumberTextTests: XCTestCase {
    func testParsesBothDecimalSeparators() {
        XCTAssertEqual(NumberText.parse("82.5"), .some(82.5))
        XCTAssertEqual(NumberText.parse("82,5"), .some(82.5))
    }

    func testClearedFieldIsNilButHalfTypedTextKeepsTheLastValue() {
        XCTAssertEqual(NumberText.parse("  "), .some(nil))
        XCTAssertNil(NumberText.parse("abc"), "not a number: leave the stored value alone")
        XCTAssertNil(NumberText.parse("-5"), "no negative grams, kcal or doses")
    }

    func testFormatDropsTrailingZerosAndRespectsDigits() {
        XCTAssertEqual(NumberText.format(nil, fractionDigits: 1), "")
        XCTAssertEqual(NumberText.parse(NumberText.format(82.5, fractionDigits: 1)), .some(82.5))
        XCTAssertEqual(NumberText.parse(NumberText.format(2500, fractionDigits: 0)), .some(2500), "no grouping separator to trip the parser")
        XCTAssertEqual(NumberText.parse(NumberText.format(70, fractionDigits: 1)), .some(70))
    }
}
