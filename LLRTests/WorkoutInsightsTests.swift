import XCTest
@testable import LLR

final class WorkoutInsightsTests: XCTestCase {
    private typealias Insights = WorkoutInsights

    private func set(_ kg: Double, _ reps: Int, _ kind: SetKind = .normal) -> SetValue {
        SetValue(weightKg: kg, reps: reps, kind: kind)
    }

    func testTotalsAreHeldAgainstTheLastWorkoutOfTheSameName() {
        let now = Insights.Totals(volumeKg: 5_200, sets: 16, duration: 3_600)
        let then = Insights.Totals(volumeKg: 5_000, sets: 15, duration: 3_900)
        let comparison = Insights.compare(now, to: then)
        XCTAssertEqual(comparison.volumeDeltaKg, 200)
        XCTAssertEqual(comparison.volumePercent ?? 0, 4, accuracy: 1e-9)
        XCTAssertEqual(comparison.setDelta, 1)
        XCTAssertEqual(comparison.durationDelta, -300)
    }

    func testThereIsNoPercentAgainstAWorkoutWithNoVolume() {
        let comparison = Insights.compare(Insights.Totals(volumeKg: 900, sets: 6, duration: 600), to: Insights.Totals(volumeKg: 0, sets: 4, duration: 600))
        XCTAssertNil(comparison.volumePercent)
    }

    func testALiftIsItsBestEstimateAgainstLastTimes() throws {
        // Now: 100 × 5 → 116.67 beats 105 × 3 → 115.5. Last time: 100 × 4 → 113.33.
        let lift = Insights.Lift(name: "Bench Press (Barbell)", sets: [set(100, 5), set(105, 3)], previous: [set(100, 4)])
        let change = try XCTUnwrap(Insights.changes([lift], formula: .epley).first)
        XCTAssertEqual(change.best, set(100, 5))
        XCTAssertEqual(change.estimateKg, 100 * (1 + 5.0 / 30), accuracy: 1e-9)
        XCTAssertEqual(change.deltaKg ?? 0, 100 * (1 + 5.0 / 30) - 100 * (1 + 4.0 / 30), accuracy: 1e-9)
    }

    func testAFirstSessionHasNothingToCompareWith() throws {
        let change = try XCTUnwrap(Insights.changes([Insights.Lift(name: "Row", sets: [set(60, 8)], previous: [])], formula: .epley).first)
        XCTAssertNil(change.deltaKg)
    }

    func testTheSameSetAsLastTimeIsExactlyNoChange() throws {
        let change = try XCTUnwrap(Insights.changes([Insights.Lift(name: "Row", sets: [set(62.5, 7)], previous: [set(62.5, 7)])], formula: .epley).first)
        XCTAssertEqual(change.deltaKg, 0)
    }

    func testWarmUpsAndSetsWithNoEstimateAreLeftOut() {
        let lifts = [
            Insights.Lift(name: "Squat", sets: [set(140, 3, .warmup), set(100, 5)], previous: [set(150, 1, .warmup), set(95, 5)]),
            Insights.Lift(name: "Push Up", sets: [set(0, 20)], previous: [set(0, 18)]),
            Insights.Lift(name: "Calf Raise", sets: [set(40, 20)], previous: [set(40, 18)]),
        ]
        let changes = Insights.changes(lifts, formula: .epley)
        XCTAssertEqual(changes.map(\.name), ["Squat"])
        XCTAssertEqual(changes.first?.best, set(100, 5))
        XCTAssertEqual(changes.first?.deltaKg ?? 0, 5 * (1 + 5.0 / 30), accuracy: 1e-9)
    }

    func testAnExerciseLoggedTwiceInOneWorkoutIsOneLift() {
        let lifts = [
            Insights.Lift(name: "Curl", sets: [set(20, 10)], previous: [set(20, 8)]),
            Insights.Lift(name: "Curl", sets: [set(22.5, 8)], previous: [set(20, 8)]),
        ]
        let changes = Insights.changes(lifts, formula: .epley)
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?.best, set(22.5, 8))
    }
}
