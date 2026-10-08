import XCTest
@testable import LLR

final class OpenGymPortTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    func testFavouritesComeFirstAndKeepOrderWithinEachHalf() {
        let items = [("a", false), ("b", true), ("c", false), ("d", true)]
        let result = ExerciseFavourites.favouritesFirst(items, isFavourite: { $0.1 }).map(\.0)
        XCTAssertEqual(result, ["b", "d", "a", "c"])
    }

    func testHeatmapIs53WeeksOf7DaysEndingInTheCurrentWeek() {
        let now = date(2026, 10, 8) // a Thursday
        let columns = ActivityHeatmap.columns(sessions: [], metric: .time, now: now, calendar: calendar)
        XCTAssertEqual(columns.count, 53)
        XCTAssertTrue(columns.allSatisfy { $0.count == 7 })
        let last = columns[52]
        XCTAssertEqual(calendar.component(.weekday, from: last[0].day), 2, "weeks start on the calendar's first weekday")
        XCTAssertEqual(last.map(\.isFuture), [false, false, false, false, true, true, true])
    }

    func testHeatmapShadesByQuartileOfTheNonZeroDays() {
        let now = date(2026, 10, 8)
        let sessions = [10, 20, 30, 40].enumerated().map { index, minutes in
            ActivityHeatmap.Session(date: date(2026, 10, 5 + index), minutes: minutes, volumeKg: 0)
        }
        let cells = ActivityHeatmap.columns(sessions: sessions, metric: .time, now: now, calendar: calendar)[52]
        XCTAssertEqual(cells.map(\.level), [1, 2, 3, 4, 0, 0, 0])
    }

    func testHeatmapSwitchesMetricAndSumsWorkoutsOnTheSameDay() {
        let now = date(2026, 10, 8)
        let sessions = [
            ActivityHeatmap.Session(date: date(2026, 10, 5), minutes: 5, volumeKg: 1000),
            ActivityHeatmap.Session(date: date(2026, 10, 5), minutes: 5, volumeKg: 1000),
            ActivityHeatmap.Session(date: date(2026, 10, 6), minutes: 60, volumeKg: 500),
        ]
        let byTime = ActivityHeatmap.columns(sessions: sessions, metric: .time, now: now, calendar: calendar)[52]
        let byVolume = ActivityHeatmap.columns(sessions: sessions, metric: .volume, now: now, calendar: calendar)[52]
        // With two active days the lowest one sits exactly on the first quartile, so it shades 2, not 1.
        XCTAssertEqual(byTime[0].level, 2)  // 10 min vs 60
        XCTAssertEqual(byTime[1].level, 4)
        XCTAssertEqual(byVolume[0].level, 4) // 2000 kg vs 500
    }

    func testWorkoutTextListsWorkSetsOnlyAndMarksDropAndFailureSets() {
        let text = WorkoutText.make(
            title: "Push", date: date(2026, 10, 8), duration: 3_660, volumeKg: 2_500, unit: .kg, notes: " felt good \n",
            entries: [
                .init(name: "Bench Press", sets: [
                    .init(kind: .warmup, weightKg: 40, reps: 10, durationSeconds: nil),
                    .init(kind: .normal, weightKg: 100, reps: 5, durationSeconds: nil),
                    .init(kind: .drop, weightKg: 80, reps: 8, durationSeconds: nil),
                    .init(kind: .failure, weightKg: 60, reps: 12, durationSeconds: nil),
                ]),
                .init(name: "Plank", sets: [.init(kind: .normal, weightKg: 0, reps: 1, durationSeconds: 60)]),
                .init(name: "Only Warm-up", sets: [.init(kind: .warmup, weightKg: 20, reps: 10, durationSeconds: nil)]),
            ]
        )
        let lines = text.components(separatedBy: "\n")
        XCTAssertTrue(lines[0].hasPrefix("Push · "))
        XCTAssertEqual(lines[1], "1h 1m · 2500 kg")
        XCTAssertTrue(text.contains("Bench Press\n100 × 5, 80 × 8 (drop), 60 × 12 (failure)"))
        XCTAssertTrue(text.contains("Plank\n1 × 60 s"))
        XCTAssertFalse(text.contains("Only Warm-up"))
        XCTAssertFalse(text.contains("40 × 10"))
        XCTAssertTrue(text.hasSuffix("\n\nfelt good"))
    }

    func testWorkoutTextHonoursLbsAndOmitsZeroVolume() {
        let text = WorkoutText.make(
            title: "Walk", date: date(2026, 10, 8), duration: 600, volumeKg: 0, unit: .lbs, notes: "",
            entries: [.init(name: "Row", sets: [.init(kind: .normal, weightKg: 45.359237, reps: 10, durationSeconds: nil)])]
        )
        XCTAssertTrue(text.contains("\n10m\n"))
        XCTAssertTrue(text.contains("Row\n100 × 10"))
    }
}
