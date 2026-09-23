import XCTest
@testable import LLR

final class RestDurationTests: XCTestCase {
    func testNilOverrideInheritsDefault() {
        XCTAssertEqual(RestDuration.resolve(override: nil, defaultSeconds: 90), 90)
    }

    func testOverrideWins() {
        XCTAssertEqual(RestDuration.resolve(override: 180, defaultSeconds: 90), 180)
    }

    func testZeroMeansOff() {
        XCTAssertNil(RestDuration.resolve(override: 0, defaultSeconds: 90))
        XCTAssertNil(RestDuration.resolve(override: nil, defaultSeconds: 0))
    }

    func testLabels() {
        XCTAssertEqual(RestDuration.label(45), "45s")
        XCTAssertEqual(RestDuration.label(120), "2min")
        XCTAssertEqual(RestDuration.label(150), "2min 30s")
        XCTAssertEqual(RestDuration.label(0), "Off")
    }
}
