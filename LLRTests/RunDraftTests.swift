import XCTest
@testable import LLR

final class RunDraftTests: XCTestCase {
    private func draft(_ km: String, _ h: String = "", _ m: String = "", _ s: String = "") -> RunDraft {
        RunDraft(kmText: km, hoursText: h, minutesText: m, secondsText: s)
    }

    func testParsesDistanceWithDotOrCommaAndTimeFromParts() {
        let value = draft("10,5", "1", "5", "30")
        XCTAssertEqual(value.distanceKm, 10.5)
        XCTAssertEqual(value.seconds, 3930)
    }

    func testEmptyTimePartsCountAsZeroButJunkIsInvalid() {
        XCTAssertEqual(draft("5", "", "30").seconds, 1800)
        XCTAssertNil(draft("5", "x", "30").seconds)
        XCTAssertNil(draft("5", "", "-3").seconds)
    }

    func testValidityNeedsBothNumbersAndAPlausiblePace() {
        XCTAssertFalse(draft("").isValid)
        XCTAssertFalse(draft("5").isValid, "no time yet")
        XCTAssertTrue(draft("5", "", "30").isValid)
        XCTAssertFalse(draft("5", "", "1").isValid, "5 km in a minute")
        XCTAssertFalse(draft("0", "", "30").isValid)
    }

    func testOnlySpeaksUpOncePaceIsImplausible() {
        XCTAssertNil(draft("5").problem)
        XCTAssertNil(draft("5", "", "30").problem)
        XCTAssertNotNil(draft("5", "", "1").problem)
    }
}
