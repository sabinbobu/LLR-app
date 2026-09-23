import XCTest
@testable import LLR

final class WeightUnitTests: XCTestCase {
    func testRoundTripThroughPounds() {
        let kg = WeightUnit.lbs.toKg(225)
        XCTAssertEqual(WeightUnit.lbs.fromKg(kg), 225, accuracy: 1e-9)
    }

    func testKgIsIdentity() {
        XCTAssertEqual(WeightUnit.kg.toKg(82.5), 82.5)
        XCTAssertEqual(WeightUnit.kg.fromKg(82.5), 82.5)
    }

    func testFormatDropsTrailingZeroAndRoundsToTenth() {
        XCTAssertEqual(WeightUnit.kg.format(kg: 100), "100")
        XCTAssertEqual(WeightUnit.kg.format(kg: 82.5), "82.5")
        XCTAssertEqual(WeightUnit.kg.format(kg: 82.46), "82.5")
        XCTAssertEqual(WeightUnit.lbs.format(kg: WeightUnit.lbs.toKg(135)), "135")
    }

    func testParseAcceptsCommaDecimal() {
        XCTAssertEqual(WeightUnit.parse("82,5"), 82.5)
        XCTAssertEqual(WeightUnit.parse("82.5"), 82.5)
        XCTAssertNil(WeightUnit.parse(""))
        XCTAssertNil(WeightUnit.parse("abc"))
    }
}

final class FormatTests: XCTestCase {
    func testDuration() {
        XCTAssertEqual(Format.duration(59), "0m")
        XCTAssertEqual(Format.duration(45 * 60), "45m")
        XCTAssertEqual(Format.duration(65 * 60), "1h 5m")
    }

    func testClock() {
        XCTAssertEqual(Format.clock(90), "1:30")
        XCTAssertEqual(Format.clock(3_725), "1:02:05")
        XCTAssertEqual(Format.clock(-5), "0:00")
    }
}
