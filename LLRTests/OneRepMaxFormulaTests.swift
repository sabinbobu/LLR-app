import XCTest
@testable import LLR

final class OneRepMaxFormulaTests: XCTestCase {
    private func day(_ n: Double) -> Date { Date(timeIntervalSince1970: n * 86_400) }

    func testEachFormulaOnTheSameFiveRepSet() {
        // Epley 100 × (1 + 5/30); Brzycki 100 × 36/(37 − 5); Lombardi 100 × 5^0.1.
        XCTAssertEqual(OneRepMax.estimate(weightKg: 100, reps: 5, formula: .epley), 116.6667, accuracy: 1e-3)
        XCTAssertEqual(OneRepMax.estimate(weightKg: 100, reps: 5, formula: .brzycki), 112.5, accuracy: 1e-9)
        XCTAssertEqual(OneRepMax.estimate(weightKg: 100, reps: 5, formula: .lombardi), 117.4619, accuracy: 1e-3)
    }

    func testASingleIsItsOwnMaxInEveryFormula() {
        for formula in OneRepMax.Formula.allCases {
            XCTAssertEqual(OneRepMax.estimate(weightKg: 140, reps: 1, formula: formula), 140, "\(formula)")
        }
    }

    func testThereIsNoEstimateAboveTwelveReps() {
        for formula in OneRepMax.Formula.allCases {
            XCTAssertGreaterThan(OneRepMax.estimate(weightKg: 60, reps: 12, formula: formula), 60, "\(formula)")
            XCTAssertEqual(OneRepMax.estimate(weightKg: 60, reps: 13, formula: formula), 0, "\(formula)")
        }
    }

    func testNoLoadOrNoRepsIsNoEstimate() {
        XCTAssertEqual(OneRepMax.estimate(weightKg: 0, reps: 5, formula: .brzycki), 0)
        XCTAssertEqual(OneRepMax.estimate(weightKg: 100, reps: 0, formula: .lombardi), 0)
    }

    func testBestSetFallsBackToTheHeaviestWhenNothingCanBeEstimated() {
        let sessions = [Session(date: day(1), sets: [SetValue(weightKg: 20, reps: 20), SetValue(weightKg: 25, reps: 15)])]
        XCTAssertEqual(ExerciseProgress.bestSet(in: sessions), SetValue(weightKg: 25, reps: 15))
    }

    func testBestSetPrefersASetThatCanBeEstimated() {
        // 60 × 20 would win on raw Epley (100), but it is past the cap; 80 × 5 is a real estimate.
        let sessions = [Session(date: day(1), sets: [SetValue(weightKg: 60, reps: 20), SetValue(weightKg: 80, reps: 5)])]
        XCTAssertEqual(ExerciseProgress.bestSet(in: sessions), SetValue(weightKg: 80, reps: 5))
    }

    func testTheOneRepMaxChartSkipsASessionOfOnlyHighRepSets() {
        let sessions = [
            Session(date: day(1), sets: [SetValue(weightKg: 80, reps: 5)]),
            Session(date: day(2), sets: [SetValue(weightKg: 50, reps: 20)]),
        ]
        XCTAssertEqual(ExerciseProgress.series(sessions, metric: .oneRepMax).map(\.date), [day(1)])
    }

    func testAHighRepSetIsNeverAOneRepMaxRecord() {
        let kinds = PersonalRecords.kinds(for: SetValue(weightKg: 50, reps: 15), history: [SetValue(weightKg: 40, reps: 15)], earlierToday: [])
        XCTAssertEqual(kinds, [.weight, .setVolume])
    }
}
