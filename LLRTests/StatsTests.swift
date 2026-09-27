import XCTest
@testable import LLR

final class StatsTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 2 // Monday
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    private func summary(_ date: Date, minutes: Double = 60, volume: Double = 1000, reps: Int = 50,
                         muscles: [String: Int] = [:]) -> WorkoutSummary {
        WorkoutSummary(date: date, duration: minutes * 60, volumeKg: volume, reps: reps, muscleSets: muscles)
    }

    func testWeeklyZeroFillsAndSumsWithinWeek() {
        // Wed 2026-09-23 is "now"; weeks start Monday 09-21, 09-14, 09-07.
        let now = date(2026, 9, 23)
        let workouts = [summary(date(2026, 9, 21), volume: 500), summary(date(2026, 9, 22), volume: 700),
                        summary(date(2026, 9, 8), volume: 300)]
        let points = Stats.weekly(workouts, metric: .volume, weeks: 3, now: now, calendar: calendar)
        XCTAssertEqual(points.map(\.value), [300, 0, 1200])
        XCTAssertEqual(points.map(\.weekStart), [date(2026, 9, 7), date(2026, 9, 14), date(2026, 9, 21)]
            .map { calendar.startOfDay(for: $0) })
    }

    func testWeeklyIgnoresWorkoutsOutsideWindow() {
        let now = date(2026, 9, 23)
        let points = Stats.weekly([summary(date(2026, 1, 5))], metric: .workouts, weeks: 4, now: now, calendar: calendar)
        XCTAssertEqual(points.map(\.value), [0, 0, 0, 0])
    }

    func testWeeklyDurationAndWorkoutCount() {
        let now = date(2026, 9, 23)
        let workouts = [summary(date(2026, 9, 21), minutes: 45), summary(date(2026, 9, 23), minutes: 15)]
        XCTAssertEqual(Stats.weekly(workouts, metric: .duration, weeks: 1, now: now, calendar: calendar).first?.value, 3600)
        XCTAssertEqual(Stats.weekly(workouts, metric: .workouts, weeks: 1, now: now, calendar: calendar).first?.value, 2)
    }

    func testRangeWeekCounts() {
        XCTAssertEqual(Stats.Range.threeMonths.weeks(since: nil), 13)
        XCTAssertEqual(Stats.Range.sixMonths.weeks(since: nil), 26)
        XCTAssertEqual(Stats.Range.year.weeks(since: nil), 52)
    }

    func testAllRangeCountsWeeksSinceTheFirstWorkout() {
        let now = date(2026, 9, 23)
        // 2026-01-05 to 2026-09-23 spans roughly 37 full weeks; the exact count matters less than
        // "noticeably more than a year's 52" never happening and "at least a few months" always holding.
        let weeks = Stats.Range.all.weeks(since: date(2026, 1, 5), now: now, calendar: calendar)
        XCTAssertGreaterThan(weeks, 30)
        XCTAssertLessThan(weeks, 45)
    }

    func testAllRangeWithNoHistoryFallsBackToOneWeek() {
        XCTAssertEqual(Stats.Range.all.weeks(since: nil), 1)
    }

    func testMuscleSplitMergesAndSortsDescending() {
        let workouts = [
            summary(date(2026, 9, 20), muscles: ["Chest": 6, "Triceps": 3]),
            summary(date(2026, 9, 22), muscles: ["Back": 8, "Chest": 4]),
            summary(date(2026, 8, 1), muscles: ["Legs": 20]),
        ]
        let split = Stats.muscleSplit(workouts, since: date(2026, 9, 1))
        XCTAssertEqual(split.map(\.group), ["Chest", "Back", "Triceps"])
        XCTAssertEqual(split.map(\.sets), [10, 8, 3])
    }
}
