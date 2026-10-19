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

    func testParseRejectsWhatWouldCrashLater() {
        XCTAssertNil(WeightUnit.parse("inf"))
        XCTAssertNil(WeightUnit.parse("nan"))
        XCTAssertNil(WeightUnit.parse("99999999999999999999"), "twenty digits typed into a weight field")
        XCTAssertEqual(WeightUnit.parse("\(Int(InputLimits.maxAmount))"), InputLimits.maxAmount)
    }

    func testFormatNeverTrapsOnACorruptValue() {
        XCTAssertEqual(WeightUnit.kg.format(kg: 1e20), "100000000000000000000")
        XCTAssertEqual(WeightUnit.kg.format(kg: .infinity), "inf")
        XCTAssertEqual(WeightUnit.kg.format(kg: .nan), "nan")
        XCTAssertEqual(WeightUnit.kg.format(kg: -0.01), "0", "no \"-0\"")
        XCTAssertEqual(WeightUnit.kg.formatLength(cm: 1e20), "100000000000000000000")
        XCTAssertEqual(MeasurementKind.bodyFat.format(1e20, unit: .kg), "100000000000000000000%")
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

    func testNonFiniteAndHugeIntervalsDontTrap() {
        XCTAssertEqual(Format.duration(.infinity), "0m")
        XCTAssertEqual(Format.duration(.nan), "0m")
        XCTAssertEqual(Format.clock(.infinity), "0:00")
        XCTAssertEqual(Format.wholeSeconds(1e30), 1_000_000_000_000_000)
        XCTAssertEqual(WorkoutExport.durationText(.infinity), "0m")
        XCTAssertEqual(RunLoad.paceLabel(secondsPerKm: .infinity), "0:00")
    }
}

final class InputLimitsTests: XCTestCase {
    func testCountAcceptsOnlyWholeNumbersInRange() {
        XCTAssertEqual(InputLimits.count(" 12 "), 12)
        XCTAssertEqual(InputLimits.count("0"), 0)
        XCTAssertNil(InputLimits.count(""))
        XCTAssertNil(InputLimits.count("-1"))
        XCTAssertNil(InputLimits.count("7.5"))
        XCTAssertNil(InputLimits.count("\(InputLimits.maxReps + 1)"))
        XCTAssertNil(InputLimits.count("9000000000000000000"), "fits in Int, but two of them overflow a session total")
        XCTAssertEqual(InputLimits.count("3600", max: InputLimits.maxSeconds), 3600)
    }
}
