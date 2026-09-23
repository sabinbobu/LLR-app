import XCTest
@testable import LLR

final class PlateCalculatorTests: XCTestCase {
    private let kg = PlateCalculator.plates(for: .kg)
    private let lbs = PlateCalculator.plates(for: .lbs)

    func testLoadsBiggestPlatesFirst() {
        let r = PlateCalculator.load(target: 100, bar: 20, plates: kg)
        XCTAssertEqual(r.perSide, [25, 15])
        XCTAssertEqual(r.loaded, 100)
        XCTAssertEqual(r.remainder, 0)
    }

    func testSmallestFractionalPlate() {
        XCTAssertEqual(PlateCalculator.load(target: 102.5, bar: 20, plates: kg).perSide, [25, 15, 1.25])
    }

    func testUnloadableTargetReportsClosestBelow() {
        let r = PlateCalculator.load(target: 101, bar: 20, plates: kg)
        XCTAssertEqual(r.perSide, [25, 15])
        XCTAssertEqual(r.loaded, 100)
        XCTAssertEqual(r.remainder, 1, accuracy: 1e-9)
    }

    func testTargetAtOrBelowBarIsEmptyBar() {
        XCTAssertEqual(PlateCalculator.load(target: 20, bar: 20, plates: kg).perSide, [])
        XCTAssertEqual(PlateCalculator.load(target: 10, bar: 20, plates: kg).loaded, 20)
    }

    func testPounds() {
        XCTAssertEqual(PlateCalculator.load(target: 225, bar: 45, plates: lbs).perSide, [45, 45])
        XCTAssertEqual(PlateCalculator.load(target: 185, bar: 45, plates: lbs).perSide, [45, 25])
    }
}
