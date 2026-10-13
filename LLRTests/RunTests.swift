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

    func testStartAndFinishARun() throws {
        let run = WorkoutFactory.startRun(in: context)
        XCTAssertTrue(run.isRun)
        XCTAssertNil(run.endedAt)
        XCTAssertTrue(run.title.hasSuffix("Run"))
        WorkoutFactory.finishRun(run, in: context)
        XCTAssertNotNil(run.endedAt)
    }

    func testAFinishedRunWithNoSetsSurvivesTheEmptyHistoryCleanup() throws {
        let run = WorkoutFactory.startRun(in: context)
        WorkoutFactory.finishRun(run, in: context)
        let emptyLift = Workout()
        emptyLift.endedAt = .now
        context.insert(emptyLift)

        WorkoutFactory.removeEmptyHistory(in: context)

        let left = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(left.map(\.isRun), [true], "the empty lift goes, the run stays")
    }

    func testRunsCountTowardTheWeekStreakButNotLiftingHistory() {
        let run = WorkoutFactory.startRun(in: context)
        WorkoutFactory.finishRun(run, in: context)
        XCTAssertEqual(TrainingCalendar.weekStreak(workouts: [run.startedAt]), 1)
        XCTAssertEqual(run.completedSets.count, 0)
        XCTAssertEqual(run.volumeKg, 0)
    }
}
