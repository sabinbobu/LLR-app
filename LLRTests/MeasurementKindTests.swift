import XCTest
@testable import LLR

final class MeasurementKindTests: XCTestCase {
    func testMassFormatsThroughTheWeightUnit() {
        XCTAssertEqual(MeasurementKind.bodyWeight.format(80, unit: .kg), "80 kg")
        XCTAssertEqual(MeasurementKind.bodyWeight.format(80, unit: .lbs), "\(WeightUnit.lbs.format(kg: 80)) lbs")
    }

    func testPercentIgnoresTheWeightUnit() {
        XCTAssertEqual(MeasurementKind.bodyFat.format(18.4, unit: .kg), "18%")
        XCTAssertEqual(MeasurementKind.bodyFat.format(18.4, unit: .lbs), "18%")
    }

    func testLengthConvertsCmToInchesForLbsUsers() {
        // 2.54 cm == 1 in exactly.
        XCTAssertEqual(WeightUnit.lbs.fromCm(2.54), 1, accuracy: 0.001)
        XCTAssertEqual(WeightUnit.kg.fromCm(2.54), 2.54, accuracy: 0.001)
    }

    func testLengthRoundTripsThroughToCmAndFromCm() {
        let originalInches = 15.5
        let cm = WeightUnit.lbs.toCm(originalInches)
        XCTAssertEqual(WeightUnit.lbs.fromCm(cm), originalInches, accuracy: 0.001)
    }

    func testLengthFormatSuffixMatchesTheWeightUnit() {
        XCTAssertEqual(MeasurementKind.waist.format(80, unit: .kg), "\(WeightUnit.kg.formatLength(cm: 80)) cm")
        XCTAssertEqual(MeasurementKind.waist.format(80, unit: .lbs), "\(WeightUnit.lbs.formatLength(cm: 80)) in")
    }

    func testEveryKindHasADimensionAndATitle() {
        for kind in MeasurementKind.allCases {
            XCTAssertFalse(kind.title.isEmpty)
            _ = kind.dimension // must not crash for any case
        }
    }
}
