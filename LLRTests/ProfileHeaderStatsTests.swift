import XCTest
@testable import LLR

final class ProfileHeaderStatsTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }()

    private func date(_ day: Int, _ hour: Int = 12, _ minute: Int = 0, month: Int = 10) -> Date {
        let parts = DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: parts) ?? .distantPast
    }

    /// Wednesday 14 Oct 2026; its week runs Monday 12 to Sunday 18.
    private var now: Date { date(14) }

    private func stats(_ starts: [Date]) -> ProfileHeaderStats {
        ProfileHeaderStats(starts: starts, now: now, calendar: calendar)
    }

    func testEmptyWeekHasAnEmptyRing() {
        let result = stats([])
        XCTAssertEqual(result.weekDays, Array(repeating: false, count: 7))
        XCTAssertEqual(result.sessionCount, 0)
        XCTAssertEqual(result.streak, 0)
        XCTAssertEqual(result.trainedDayCount, 0)
    }

    func testRingMarksExactlyTheTrainedDaysInCalendarWeekOrder() {
        let result = stats([date(12), date(14), date(18)])
        XCTAssertEqual(result.weekDays, [true, false, true, false, false, false, true])
    }

    func testWeekBoundariesAreInclusiveAtStartAndExclusiveAtEnd() {
        let before = date(11, 23, 59)
        let first = date(12, 0, 0)
        let last = date(18, 23, 59)
        let after = date(19, 0, 0)
        XCTAssertEqual(stats([before, after]).weekDays, Array(repeating: false, count: 7))
        XCTAssertEqual(stats([first, last]).weekDays, [true, false, false, false, false, false, true])
    }

    func testTwoSessionsOnOneDayFillOneSegmentButCountTwice() {
        let result = stats([date(13, 7), date(13, 19)])
        XCTAssertEqual(result.trainedDayCount, 1)
        XCTAssertEqual(result.sessionCount, 2)
    }

    func testLiftsAndRunsBothCountBecauseTheyShareOneStartList() {
        // A run is a Workout like any other, so the caller passes both kinds in one list.
        let lift = date(12)
        let run = date(15)
        let result = stats([lift, run])
        XCTAssertEqual(result.sessionCount, 2)
        XCTAssertEqual(result.weekDays, [true, false, false, true, false, false, false])
    }

    func testStreakEqualsTrainingCalendarWeekStreak() {
        let starts = [date(14), date(8), date(1), date(20, month: 9)]
        let expected = TrainingCalendar.weekStreak(workouts: starts, now: now, calendar: calendar)
        XCTAssertEqual(stats(starts).streak, expected)
        XCTAssertEqual(expected, 3)
    }

    func testSpokenSummaryReadsAsOneSentence() {
        let text = ProfileHeaderStats.spokenSummary(
            name: "Sabeen", age: 28, height: "169", heightUnit: "centimetres",
            goal: "Gain Strength", sessions: 4, streak: 2)
        XCTAssertEqual(text, "Sabeen, 28, 169 centimetres, goal gain strength, 4 sessions, 2 week streak")
    }

    func testSpokenSummarySingularAndMissingParts() {
        let text = ProfileHeaderStats.spokenSummary(
            name: "", age: 30, height: "170", heightUnit: "centimetres",
            goal: nil, sessions: 1, streak: 0)
        XCTAssertEqual(text, "Profile, 30, 170 centimetres, 1 session, 0 week streak")
    }
}
