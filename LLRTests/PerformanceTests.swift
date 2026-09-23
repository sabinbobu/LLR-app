import XCTest
@testable import LLR

final class OneRepMaxTests: XCTestCase {
    func testEpleyFormula() {
        XCTAssertEqual(OneRepMax.epley(weightKg: 100, reps: 10), 100 * (1 + 10.0 / 30), accuracy: 1e-9)
    }

    func testSingleIsTrueMax() {
        XCTAssertEqual(OneRepMax.epley(weightKg: 140, reps: 1), 140)
    }

    func testZeroRepsOrWeightIsZero() {
        XCTAssertEqual(OneRepMax.epley(weightKg: 100, reps: 0), 0)
        XCTAssertEqual(OneRepMax.epley(weightKg: 0, reps: 5), 0)
    }
}

final class PreviousPerformanceTests: XCTestCase {
    private let old = Session(date: Date(timeIntervalSince1970: 1_000), sets: [SetValue(weightKg: 50, reps: 5)])
    private let recent = Session(
        date: Date(timeIntervalSince1970: 2_000),
        sets: [SetValue(weightKg: 60, reps: 8), SetValue(weightKg: 62.5, reps: 6)]
    )

    func testLatestSetsPicksNewestSessionRegardlessOfOrder() {
        XCTAssertEqual(PreviousPerformance.latestSets(in: [recent, old]), recent.sets)
        XCTAssertEqual(PreviousPerformance.latestSets(in: [old, recent]), recent.sets)
    }

    func testLatestSetsSkipsEmptySessions() {
        let emptyNewer = Session(date: Date(timeIntervalSince1970: 3_000), sets: [])
        XCTAssertEqual(PreviousPerformance.latestSets(in: [old, emptyNewer]), old.sets)
    }

    func testLatestSetsEmptyWhenNoHistory() {
        XCTAssertEqual(PreviousPerformance.latestSets(in: []), [])
    }

    func testPrefillUsesSamePositionFromLastTime() {
        let value = PreviousPerformance.prefill(index: 1, previous: recent.sets, currentLast: SetValue(weightKg: 99, reps: 1))
        XCTAssertEqual(value, SetValue(weightKg: 62.5, reps: 6))
    }

    func testPrefillBeyondPreviousRepeatsCurrentLast() {
        let current = SetValue(weightKg: 65, reps: 5)
        XCTAssertEqual(PreviousPerformance.prefill(index: 2, previous: recent.sets, currentLast: current), current)
    }

    func testPrefillBeyondPreviousWithNoCurrentFallsBackToPreviousLast() {
        XCTAssertEqual(PreviousPerformance.prefill(index: 5, previous: recent.sets, currentLast: nil), recent.sets.last)
    }

    func testPrefillNilWithNoHistory() {
        XCTAssertNil(PreviousPerformance.prefill(index: 0, previous: [], currentLast: nil))
    }
}

final class ExerciseProgressTests: XCTestCase {
    private let sessions = [
        Session(date: Date(timeIntervalSince1970: 2_000), sets: [SetValue(weightKg: 100, reps: 5), SetValue(weightKg: 105, reps: 1)]),
        Session(date: Date(timeIntervalSince1970: 1_000), sets: [SetValue(weightKg: 90, reps: 10)]),
    ]

    func testBestSetIsHighestEstimated1RM() {
        // 90×10 → 120, 100×5 → 116.7, 105×1 → 105
        XCTAssertEqual(ExerciseProgress.bestSet(in: sessions), SetValue(weightKg: 90, reps: 10))
    }

    func testBestSetTieBreaksOnHeavierWeight() {
        // 100×3 and 110×1 → both exactly 110.
        let tied = [Session(date: .now, sets: [SetValue(weightKg: 100, reps: 3), SetValue(weightKg: 110, reps: 1)])]
        XCTAssertEqual(ExerciseProgress.bestSet(in: tied), SetValue(weightKg: 110, reps: 1))
    }

    func testBestSetNilWhenOnlyEmptySets() {
        XCTAssertNil(ExerciseProgress.bestSet(in: [Session(date: .now, sets: [SetValue(weightKg: 0, reps: 0)])]))
    }

    func testSeriesAreChronologicalWithPerSessionMax() {
        let heaviest = ExerciseProgress.heaviestWeightSeries(sessions)
        XCTAssertEqual(heaviest.map(\.value), [90, 105])
        XCTAssertEqual(heaviest.map(\.date), [Date(timeIntervalSince1970: 1_000), Date(timeIntervalSince1970: 2_000)])

        let e1rm = ExerciseProgress.oneRepMaxSeries(sessions)
        XCTAssertEqual(e1rm[0].value, 120, accuracy: 1e-9)
        XCTAssertEqual(e1rm[1].value, 100 * (1 + 5.0 / 30), accuracy: 1e-9)
    }
}
