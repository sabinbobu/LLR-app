import XCTest
@testable import LLR

final class BodyCompositionTests: XCTestCase {
    func testBMI() throws {
        XCTAssertEqual(try XCTUnwrap(BodyComposition.bmi(weightKg: 80, heightCm: 180)), 24.69, accuracy: 0.01)
        XCTAssertNil(BodyComposition.bmi(weightKg: 80, heightCm: nil))
    }

    func testLeanMass() throws {
        XCTAssertEqual(try XCTUnwrap(BodyComposition.leanMassKg(weightKg: 80, bodyFatPercent: 15)), 68, accuracy: 1e-9)
        XCTAssertNil(BodyComposition.leanMassKg(weightKg: 80, bodyFatPercent: nil))
        XCTAssertNil(BodyComposition.leanMassKg(weightKg: 80, bodyFatPercent: 120))
    }

    func testWaistToHeightZonesMatchNICE() {
        XCTAssertEqual(BodyComposition.zone(forWaistToHeight: 0.499), .healthy)
        XCTAssertEqual(BodyComposition.zone(forWaistToHeight: 0.5), .increased)
        XCTAssertEqual(BodyComposition.zone(forWaistToHeight: 0.599), .increased)
        XCTAssertEqual(BodyComposition.zone(forWaistToHeight: 0.6), .high)
        XCTAssertEqual(BodyComposition.waistToHeight(waistCm: 90, heightCm: 180), 0.5)
    }

    func testLatestPicksNewestOfKind() {
        let old = BodyMeasurement(kind: .waist, value: 90, takenAt: Date(timeIntervalSince1970: 0))
        let new = BodyMeasurement(kind: .waist, value: 86, takenAt: Date(timeIntervalSince1970: 100))
        let other = BodyMeasurement(kind: .chest, value: 100, takenAt: Date(timeIntervalSince1970: 200))
        XCTAssertEqual(BodyComposition.latest(.waist, in: [new, other, old])?.value, 86)
        XCTAssertNil(BodyComposition.latest(.hips, in: [new, other, old]))
    }
}
