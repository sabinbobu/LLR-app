import XCTest
@testable import LLR

final class TrainingCalendarTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 2 // Monday
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    // MARK: trainedDays

    func testTrainedDaysOnlyIncludesDaysInTheGivenMonth() {
        let workouts = [date(2026, 8, 31), date(2026, 9, 1), date(2026, 9, 15), date(2026, 10, 1)]
        let days = TrainingCalendar.trainedDays(in: date(2026, 9, 10), workouts: workouts, calendar: calendar)
        XCTAssertEqual(days, [calendar.startOfDay(for: date(2026, 9, 1)), calendar.startOfDay(for: date(2026, 9, 15))])
    }

    func testTwoWorkoutsOnTheSameDayCountOnce() {
        let days = TrainingCalendar.trainedDays(
            in: date(2026, 9, 10), workouts: [date(2026, 9, 5, hour: 8), date(2026, 9, 5, hour: 18)], calendar: calendar
        )
        XCTAssertEqual(days.count, 1)
    }

    // MARK: weekStreak

    func testStreakCountsConsecutiveTrainedWeeksBackFromNow() {
        // Weeks start Monday. "Now" is in the week of 2026-09-21.
        let now = date(2026, 9, 23)
        // Trained the current week and the two before it; 8/25 falls one week further back, past a
        // gap week (8/31–9/6) that has nothing, so it must not extend the streak.
        let workouts = [date(2026, 9, 22), date(2026, 9, 15), date(2026, 9, 8), date(2026, 8, 25)]
        XCTAssertEqual(TrainingCalendar.weekStreak(workouts: workouts, now: now, calendar: calendar), 3)
    }

    func testAnUntrainedCurrentWeekDoesNotBreakTheStreakYet() {
        let now = date(2026, 9, 23)
        // Nothing trained this week, but last week and the week before were.
        let workouts = [date(2026, 9, 15), date(2026, 9, 8)]
        XCTAssertEqual(TrainingCalendar.weekStreak(workouts: workouts, now: now, calendar: calendar), 2)
    }

    func testAGapEndsTheStreak() {
        let now = date(2026, 9, 23)
        let workouts = [date(2026, 9, 22), date(2026, 9, 1)] // this week trained, last week not
        XCTAssertEqual(TrainingCalendar.weekStreak(workouts: workouts, now: now, calendar: calendar), 1)
    }

    func testNoHistoryIsAZeroStreak() {
        XCTAssertEqual(TrainingCalendar.weekStreak(workouts: [], now: date(2026, 9, 23), calendar: calendar), 0)
    }

    func testStreakCrossesAYearBoundary() {
        let now = date(2027, 1, 6) // first week of 2027
        let workouts = [date(2027, 1, 5), date(2026, 12, 29), date(2026, 12, 22)]
        XCTAssertEqual(TrainingCalendar.weekStreak(workouts: workouts, now: now, calendar: calendar), 3)
    }
}
