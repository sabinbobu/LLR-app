import XCTest
@testable import LLR

/// Expected values are worked out by hand from the rules, not copied from another implementation.
final class EffortStatsTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }()
    // Monday 2026-09-21 00:00 UTC, as in WeeklyVolumeTests.
    private let weekStart = Date(timeIntervalSince1970: 1_789_948_800)
    private let week: TimeInterval = 7 * 86_400

    private func samples(_ ratings: [Double?], at date: Date? = nil) -> [EffortStats.Sample] {
        ratings.map { EffortStats.Sample(date: date ?? weekStart, rir: $0) }
    }

    func testSummaryAveragesRatedSetsAndKeepsTheDenominator() {
        // 0+1+2+3+4 = 10 over 5 rated; four of them are at 3 or fewer in reserve.
        let summary = EffortStats.summary(samples([0, 1, 2, 3, 4, nil]))
        XCTAssertEqual(summary, .init(done: 6, rated: 5, hard: 4, averageRir: 2, hardShare: 0.8))
    }

    func testSummaryWithholdsAveragesBelowFiveRatedSets() {
        let summary = EffortStats.summary(samples([0, 1, 2, 3, nil, nil]))
        XCTAssertEqual(summary, .init(done: 6, rated: 4, hard: 4, averageRir: nil, hardShare: nil))
        XCTAssertEqual(EffortStats.summary([]), .init(done: 0, rated: 0, hard: 0, averageRir: nil, hardShare: nil))
    }

    func testWeeksAverageByCalendarWeekOldestFirstAndDropSingleRatedWeeks() {
        let all = samples([0, 0], at: weekStart.addingTimeInterval(-week + 3600))
            + samples([1, 3, nil], at: weekStart.addingTimeInterval(2 * 86_400))
            + samples([2, nil, nil], at: weekStart.addingTimeInterval(week + 86_400))
        let weeks = EffortStats.weeks(all.shuffled(), calendar: calendar)
        XCTAssertEqual(weeks, [
            .init(weekStart: weekStart.addingTimeInterval(-week), averageRir: 0, rated: 2, sets: 2),
            .init(weekStart: weekStart, averageRir: 2, rated: 2, sets: 3),
        ])
    }

    func testHistogramFloorsIntoWholeStepsAndCollapsesTheTail() {
        // Floors: 0, 0, 1, 2, 3, 4, and 7 joins the 4+ tail; the unrated set is not counted.
        let buckets = EffortStats.histogram(samples([0, 0.5, 1.5, 2, 3.5, 4, 7, nil]))
        XCTAssertEqual(buckets.map(\.rir), [0, 1, 2, 3, 4])
        XCTAssertEqual(buckets.map(\.count), [2, 1, 1, 1, 2])
        XCTAssertEqual(buckets[0].share, 2.0 / 7.0, accuracy: 0.0001)
        XCTAssertEqual(buckets.map(\.share).reduce(0, +), 1, accuracy: 0.0001)
        XCTAssertEqual(buckets.map(\.isTail), [false, false, false, false, true])
    }

    func testHistogramOfNothingIsFiveEmptyBuckets() {
        let buckets = EffortStats.histogram(samples([nil, nil]))
        XCTAssertEqual(buckets.map(\.count), [0, 0, 0, 0, 0])
        XCTAssertEqual(buckets.map(\.share), [0, 0, 0, 0, 0])
    }
}
