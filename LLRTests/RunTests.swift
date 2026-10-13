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
        let summary = RunStats.summary([
            (date(7), date(7, 30)), (date(7, 10, day: 2), date(8, 10, day: 2)), (date(18, 0, day: 3), date(18, 20, day: 3)),
        ], calendar: cal)
        XCTAssertEqual(summary.count, 3)
        XCTAssertEqual(summary.totalSeconds, 30 * 60 + 60 * 60 + 20 * 60)
        XCTAssertEqual(summary.averageSeconds, (110 * 60) / 3, accuracy: 0.001)
        XCTAssertEqual(summary.typicalHour, 7)
    }

    func testUsualHourTieGoesToTheEarlierHourAndEmptyIsNil() {
        let tie = RunStats.summary([(date(18), date(19)), (date(6), date(7))], calendar: cal)
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
