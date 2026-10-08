import XCTest
@testable import LLR

final class ExerciseProgressMetricTests: XCTestCase {
    private func day(_ n: Double) -> Date { Date(timeIntervalSince1970: n * 86_400) }

    func testMostRepsIgnoresWarmUps() {
        let sessions = [
            Session(date: day(1), sets: [SetValue(weightKg: 20, reps: 20, kind: .warmup), SetValue(weightKg: 60, reps: 8), SetValue(weightKg: 60, reps: 11)]),
        ]
        XCTAssertEqual(ExerciseProgress.series(sessions, metric: .maxReps).map(\.value), [11])
    }

    func testEffortAveragesRatedSetsAndSkipsUnratedSessions() {
        let sessions = [
            Session(date: day(2), sets: [SetValue(weightKg: 60, reps: 8)]),
            Session(date: day(1), sets: [SetValue(weightKg: 60, reps: 8, rir: 3), SetValue(weightKg: 60, reps: 8, rir: 1), SetValue(weightKg: 60, reps: 7)]),
        ]
        XCTAssertEqual(ExerciseProgress.series(sessions, metric: .effort), [ExerciseProgress.Point(date: day(1), value: 2)])
    }

    func testTopSetIsTheHeaviestWeightPerSession() {
        let sessions = [Session(date: day(1), sets: [SetValue(weightKg: 60, reps: 8), SetValue(weightKg: 70, reps: 3)])]
        XCTAssertEqual(ExerciseProgress.series(sessions, metric: .topSet).map(\.value), [70])
    }

    func testAssistedTopSetIsTheLeastHelp() {
        let sessions = [
            // 0 means no load was typed in, not an unassisted rep.
            Session(date: day(1), sets: [SetValue(weightKg: 30, reps: 8), SetValue(weightKg: 20, reps: 6), SetValue(weightKg: 0, reps: 5)]),
            Session(date: day(2), sets: [SetValue(weightKg: 0, reps: 5)]),
        ]
        XCTAssertEqual(ExerciseProgress.series(sessions, metric: .topSet, assisted: true), [ExerciseProgress.Point(date: day(1), value: 20)])
    }

    func testAssistedBestSetIsLeastHelpThenMostReps() {
        let sessions = [
            Session(date: day(1), sets: [SetValue(weightKg: 30, reps: 12), SetValue(weightKg: 20, reps: 6)]),
            Session(date: day(2), sets: [SetValue(weightKg: 20, reps: 8), SetValue(weightKg: 0, reps: 9)]),
        ]
        XCTAssertEqual(ExerciseProgress.bestSet(in: sessions, assisted: true), SetValue(weightKg: 20, reps: 8))
        XCTAssertEqual(ExerciseProgress.bestSet(in: sessions, assisted: false), ExerciseProgress.bestSet(in: sessions))
    }

    func testAssistedIsReadFromTheName() {
        XCTAssertTrue(ExerciseProgress.isAssisted(name: "Pull Up (Assisted)"))
        XCTAssertTrue(ExerciseProgress.isAssisted(name: "assisted dip"))
        XCTAssertFalse(ExerciseProgress.isAssisted(name: "Pull Up"))
    }

    func testOfferedMetricsDropOneRepMaxWhenAssistedAndEffortWhenNothingIsRated() {
        XCTAssertEqual(ExerciseProgress.metrics(assisted: false, rated: false), [.oneRepMax, .topSet, .maxReps])
        XCTAssertEqual(ExerciseProgress.metrics(assisted: false, rated: true), [.oneRepMax, .topSet, .maxReps, .effort])
        XCTAssertEqual(ExerciseProgress.metrics(assisted: true, rated: true), [.topSet, .maxReps, .effort])
    }

    func testRecentSessionsAreNewestFirstCappedAndWorkingSetsOnly() {
        let warmup = SetValue(weightKg: 20, reps: 10, kind: .warmup)
        var sessions = (1...7).map { Session(date: day(Double($0)), sets: [warmup, SetValue(weightKg: 50 + Double($0), reps: 5)]) }
        sessions.append(Session(date: day(8), sets: [warmup]))
        let recent = ExerciseProgress.recent(sessions.shuffled())
        XCTAssertEqual(recent.map(\.date), [day(7), day(6), day(5), day(4), day(3)])
        XCTAssertEqual(recent[0].sets, [SetValue(weightKg: 57, reps: 5)])
    }

    func testSetsTextGroupsNothingAndPicksTheRightShapePerSet() {
        let sets = [
            SetValue(weightKg: 60, reps: 8),
            SetValue(weightKg: 62.5, reps: 6),
            SetValue(weightKg: 0, reps: 12),
            SetValue(weightKg: 0, reps: 3, durationSeconds: 30),
        ]
        XCTAssertEqual(ExerciseProgress.setsText(sets, unit: .kg), "60 × 8, 62.5 × 6, 12 reps, 3 × 30 s")
    }

    func testASetCarriesItsEffortRatingIntoItsValue() {
        let set = SetEntry(order: 0, weightKg: 60, reps: 8)
        set.rir = 2
        XCTAssertEqual(set.value.rir, 2)
    }
}
