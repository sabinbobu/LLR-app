import XCTest
@testable import LLR

final class RunLoadTests: XCTestCase {
    private let mph = 1.609344

    func testPaceAndSpeed() {
        XCTAssertEqual(RunLoad.speedKmh(km: 10, seconds: 3000), 12.0, accuracy: 0.001)
        XCTAssertEqual(RunLoad.paceSecondsPerKm(km: 10, seconds: 3000), 300, accuracy: 0.001)
        XCTAssertEqual(RunLoad.paceLabel(secondsPerKm: 300), "5:00")
        XCTAssertEqual(RunLoad.paceLabel(secondsPerKm: 335), "5:35")
    }

    func testMetHitsTheTableAndInterpolatesBetweenRows() {
        XCTAssertEqual(RunLoad.met(atKmh: 6 * mph), 9.8, accuracy: 0.001)
        XCTAssertEqual(RunLoad.met(atKmh: 8 * mph), 11.8, accuracy: 0.001)
        let between = RunLoad.met(atKmh: 6.5 * mph)
        XCTAssertGreaterThan(between, 9.8)
        XCTAssertLessThan(between, 10.5)
    }

    func testMetIsClampedAtBothEnds() {
        XCTAssertEqual(RunLoad.met(atKmh: 3), 6.0, accuracy: 0.001)
        XCTAssertEqual(RunLoad.met(atKmh: 30), 16.0, accuracy: 0.001)
    }

    func testMetIsNeverDecreasingWithSpeed() {
        var previous = 0.0
        for tenth in 30...250 {
            let value = RunLoad.met(atKmh: Double(tenth) / 10)
            XCTAssertGreaterThanOrEqual(value, previous)
            previous = value
        }
    }

    func testLongerOrFasterRunsNeverTireLess() {
        let base = RunLoad.metHours(km: 5, seconds: 1800)
        XCTAssertGreaterThan(RunLoad.metHours(km: 10, seconds: 3600), base, "twice as long at the same speed")
        XCTAssertGreaterThan(RunLoad.metHours(km: 6, seconds: 1800), base, "faster over the same time")
    }

    func testOverallExhaustionScaleAndCap() {
        let fiveK = RunLoad.overallExhaustionPercent(metHours: RunLoad.metHours(km: 5, seconds: 1800))
        let tenK = RunLoad.overallExhaustionPercent(metHours: RunLoad.metHours(km: 10, seconds: 3300))
        XCTAssertGreaterThan(tenK, fiveK)
        XCTAssertGreaterThan(fiveK, 10)
        XCTAssertLessThan(tenK, 60)
        XCTAssertEqual(RunLoad.overallExhaustionPercent(metHours: 1000), 100)
        XCTAssertEqual(RunLoad.overallExhaustionPercent(metHours: 0), 0)
    }

    func testExhaustionFadesLinearlyToZero() {
        XCTAssertEqual(RunLoad.remainingExhaustion(60, hoursSince: 0), 60, accuracy: 0.001)
        XCTAssertEqual(RunLoad.remainingExhaustion(60, hoursSince: 36), 30, accuracy: 0.001)
        XCTAssertEqual(RunLoad.remainingExhaustion(60, hoursSince: 100), 0)
    }

    func testMuscleLoadsRankLegsAboveCoreAndLeaveTheUpperBodyOut() {
        let loads = RunLoad.muscleLoads(metHours: 8)
        let byMuscle = Dictionary(uniqueKeysWithValues: loads.map { ($0.muscle, $0.points) })
        XCTAssertEqual(byMuscle[.quadriceps] ?? 0, 8 * 0.8, accuracy: 0.001)
        XCTAssertGreaterThan(byMuscle[.quadriceps] ?? 0, byMuscle[.hamstrings] ?? 0)
        XCTAssertGreaterThan(byMuscle[.hamstrings] ?? 0, byMuscle[.abdominals] ?? 0)
        XCTAssertNil(byMuscle[.chest])
        XCTAssertNil(byMuscle[.biceps])
        XCTAssertEqual(RunLoad.MuscleLoad(muscle: .quadriceps, points: 20).percentDrop, 100, "capped")
    }

    func testPlausibilityRejectsWalkingPaceAndSprintsAndNonsense() {
        XCTAssertTrue(RunLoad.isPlausible(km: 10, seconds: 3000))
        XCTAssertFalse(RunLoad.isPlausible(km: 1, seconds: 3600), "1 km/h is not a run")
        XCTAssertFalse(RunLoad.isPlausible(km: 10, seconds: 600), "60 km/h")
        XCTAssertFalse(RunLoad.isPlausible(km: 0, seconds: 600))
        XCTAssertFalse(RunLoad.isPlausible(km: 5, seconds: 0))
    }
}
