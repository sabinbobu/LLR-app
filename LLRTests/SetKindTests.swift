import XCTest
@testable import LLR

final class SetKindTests: XCTestCase {
    func testWarmupsAreSkippedInWorkingNumbering() {
        XCTAssertEqual(SetKind.labels(for: [.warmup, .warmup, .normal, .normal]), ["W", "W", "1", "2"])
    }

    func testDropAndFailureShowBadgeButStillCount() {
        XCTAssertEqual(SetKind.labels(for: [.normal, .drop, .normal, .failure]), ["1", "D", "3", "F"])
    }

    func testWarmupsExcludedFromBestSet() {
        let sessions = [Session(date: .now, sets: [
            SetValue(weightKg: 200, reps: 5, kind: .warmup),
            SetValue(weightKg: 100, reps: 5),
        ])]
        XCTAssertEqual(ExerciseProgress.bestSet(in: sessions), SetValue(weightKg: 100, reps: 5))
    }

    func testWarmupOnlySessionDropsOutOfSeries() {
        let sessions = [
            Session(date: Date(timeIntervalSince1970: 1), sets: [SetValue(weightKg: 40, reps: 10, kind: .warmup)]),
            Session(date: Date(timeIntervalSince1970: 2), sets: [SetValue(weightKg: 40, reps: 10, kind: .warmup),
                                                                 SetValue(weightKg: 80, reps: 5)]),
        ]
        XCTAssertEqual(ExerciseProgress.heaviestWeightSeries(sessions).map(\.value), [80])
    }

    func testPrefillKeepsKindAtSamePosition() {
        let previous = [SetValue(weightKg: 40, reps: 10, kind: .warmup), SetValue(weightKg: 80, reps: 5)]
        XCTAssertEqual(PreviousPerformance.prefill(index: 0, previous: previous, currentLast: nil)?.kind, .warmup)
    }

    func testPrefillBeyondPreviousIsAlwaysNormal() {
        let previous = [SetValue(weightKg: 80, reps: 5), SetValue(weightKg: 60, reps: 8, kind: .drop)]
        let extra = PreviousPerformance.prefill(index: 2, previous: previous, currentLast: previous.last)
        XCTAssertEqual(extra, SetValue(weightKg: 60, reps: 8, kind: .normal))
    }
}
