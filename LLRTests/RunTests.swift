import SwiftData
import XCTest
@testable import LLR

@MainActor
final class RunTests: XCTestCase {
    private var context: ModelContext!
    private var cal: Calendar!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
    }

    private func date(_ hour: Int, _ minute: Int = 0, day: Int = 1) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour, minute: minute))!
    }

    func testSummaryTotalsAverageAndUsualHour() {
        var runs: [(start: Date, end: Date)] = []
        runs.append((start: date(7, 0, day: 1), end: date(7, 30, day: 1)))
        runs.append((start: date(7, 10, day: 2), end: date(8, 10, day: 2)))
        runs.append((start: date(18, 0, day: 3), end: date(18, 20, day: 3)))

        let summary = RunStats.summary(runs, calendar: cal)

        let totalMinutes: Double = 30 + 60 + 20
        XCTAssertEqual(summary.count, 3)
        XCTAssertEqual(summary.totalSeconds, totalMinutes * 60, accuracy: 0.001)
        XCTAssertEqual(summary.averageSeconds, totalMinutes * 60 / 3, accuracy: 0.001)
        XCTAssertEqual(summary.typicalHour, 7)
    }

    func testUsualHourTieGoesToTheEarlierHourAndEmptyIsNil() {
        var runs: [(start: Date, end: Date)] = []
        runs.append((start: date(18), end: date(19)))
        runs.append((start: date(6), end: date(7)))
        let tie = RunStats.summary(runs, calendar: cal)
        XCTAssertEqual(tie.typicalHour, 6)
        let none = RunStats.summary([], calendar: cal)
        XCTAssertEqual(none, RunStats.Summary(count: 0, totalSeconds: 0, averageSeconds: 0, typicalHour: nil))
    }

    func testAddRunStoresAFinishedRunWithDistanceAndDerivedStart() throws {
        let finished = date(8, 0, day: 5)
        let run = WorkoutFactory.addRun(distanceKm: 10, seconds: 3000, finishedAt: finished, in: context)

        XCTAssertTrue(run.isRun)
        XCTAssertEqual(run.distanceKm, 10)
        XCTAssertEqual(run.endedAt, finished)
        XCTAssertEqual(run.startedAt, finished.addingTimeInterval(-3000))
        XCTAssertEqual(run.duration, 3000, accuracy: 0.001)
        XCTAssertTrue(run.title.hasSuffix("Run"))
    }

    func testAFinishedRunWithNoSetsSurvivesTheEmptyHistoryCleanup() throws {
        WorkoutFactory.addRun(distanceKm: 5, seconds: 1800, finishedAt: .now, in: context)
        let emptyLift = Workout()
        emptyLift.endedAt = .now
        context.insert(emptyLift)

        WorkoutFactory.removeEmptyHistory(in: context)

        let left = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(left.map(\.isRun), [true], "the empty lift goes, the run stays")
    }

    func testUnfinishedRunsFromTheOldStopwatchAreDiscarded() throws {
        let stale = Workout()
        stale.sectionRaw = RunStats.sectionRaw
        context.insert(stale)
        let openLift = Workout()
        context.insert(openLift)
        WorkoutFactory.addRun(distanceKm: 5, seconds: 1800, finishedAt: .now, in: context)

        WorkoutFactory.discardUnfinishedRuns(in: context)

        let left = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(left.count, 2, "the stale run goes; the open lift and the finished run stay")
        XCTAssertFalse(left.contains { $0.isRun && $0.endedAt == nil })
    }

    func testRunsCountTowardTheWeekStreakButNotLiftingHistory() {
        let run = WorkoutFactory.addRun(distanceKm: 5, seconds: 1800, finishedAt: .now, in: context)
        XCTAssertEqual(TrainingCalendar.weekStreak(workouts: [run.startedAt]), 1)
        XCTAssertEqual(run.completedSets.count, 0)
        XCTAssertEqual(run.volumeKg, 0)
    }

    func testARunTiresLegsMostAndStaysOutOfWeeklyVolume() throws {
        let run = WorkoutFactory.addRun(distanceKm: 10, seconds: 3000, finishedAt: .now, in: context)

        XCTAssertTrue(run.recoveryEntries.isEmpty, "a run is not a hard set")
        let statuses = MuscleRecovery.statuses(for: run.exhaustionEntries, now: .now)
        let quads = try XCTUnwrap(statuses[.quadriceps]).percent
        let lowerBack = try XCTUnwrap(statuses[.lowerBack]).percent
        let chest = try XCTUnwrap(statuses[.chest]).percent
        XCTAssertLessThan(quads, lowerBack, "legs are hit harder than the lower back")
        XCTAssertLessThan(lowerBack, 100)
        XCTAssertEqual(chest, 100, "upper body is untouched")
        XCTAssertTrue(WeeklyVolume.sets(run.recoveryEntries, week: .now).isEmpty)
    }

    func testOldTimeOnlyRunsCostNothingBecauseTheirDistanceIsUnknown() {
        let old = Workout(startedAt: date(7))
        old.sectionRaw = RunStats.sectionRaw
        old.endedAt = date(7, 30)
        XCTAssertNil(old.runMetHours)
        XCTAssertTrue(old.exhaustionEntries.isEmpty)
    }

    func testRecentRunLowersOverallRecoveryAndItFades() {
        let run = WorkoutFactory.addRun(distanceKm: 10, seconds: 3000, finishedAt: .now, in: context)
        let now = Date.now
        let fresh = MuscleRecoveryInput.overall(for: [run], now: now)
        let later = MuscleRecoveryInput.overall(for: [run], now: now.addingTimeInterval(80 * 3600))
        XCTAssertLessThan(fresh, 100)
        XCTAssertEqual(later, 100, accuracy: 0.001)
        XCTAssertGreaterThan(MuscleRecoveryInput.systemicExhaustion(for: [run], now: now), 0)
    }
}
