import XCTest
@testable import LLR

final class WeightTrendTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    private let start = Date(timeIntervalSince1970: 1_789_948_800) // 2026-09-21 00:00 UTC

    private func day(_ n: Int, hour: Int = 7) -> Date { start.addingTimeInterval(Double(n) * 86_400 + Double(hour) * 3600) }

    func testConstantWeightTrendsFlat() {
        let points = WeightTrend.points((0..<10).map { (day($0), 80.0) }, calendar: calendar)
        XCTAssertEqual(points.count, 10)
        XCTAssertTrue(points.allSatisfy { $0.trend == 80 })
        XCTAssertEqual(try XCTUnwrap(WeightTrend.weeklyRate(points)), 0, accuracy: 1e-9)
    }

    func testStepMovesTheTrendTenPercentPerDay() {
        let points = WeightTrend.points([(day(0), 80), (day(1), 90)], calendar: calendar)
        XCTAssertEqual(points[1].trend, 81, accuracy: 1e-9)
    }

    func testGapsAreInterpolatedAndMarkedAsNotWeighed() {
        let points = WeightTrend.points([(day(0), 80), (day(4), 84)], calendar: calendar)
        XCTAssertEqual(points.count, 5)
        XCTAssertEqual(points.map(\.raw), [80, nil, nil, nil, 84])
        // Interpolated 81, 82, 83, 84 each pull the trend 10% of the way.
        var trend = 80.0
        for weight in [81.0, 82, 83, 84] { trend += 0.1 * (weight - trend) }
        XCTAssertEqual(points.last!.trend, trend, accuracy: 1e-9)
    }

    func testEarliestWeighInOfTheDayWins() {
        let points = WeightTrend.points([(day(0, hour: 20), 82), (day(0, hour: 7), 80)], calendar: calendar)
        XCTAssertEqual(points.first?.raw, 80)
    }

    func testWeeklyRateSignFollowsDirection() throws {
        let losing = WeightTrend.points((0..<14).map { (day($0), 90 - Double($0) * 0.1) }, calendar: calendar)
        XCTAssertLessThan(try XCTUnwrap(WeightTrend.weeklyRate(losing)), 0)
        let gaining = WeightTrend.points((0..<14).map { (day($0), 70 + Double($0) * 0.1) }, calendar: calendar)
        XCTAssertGreaterThan(try XCTUnwrap(WeightTrend.weeklyRate(gaining)), 0)
        XCTAssertNil(WeightTrend.weeklyRate(Array(losing.prefix(1))))
    }

    func testTrendOnDateClampsToTheSeries() {
        let points = WeightTrend.points([(day(0), 80), (day(2), 82)], calendar: calendar)
        XCTAssertEqual(WeightTrend.trend(on: day(-5), in: points, calendar: calendar), 80)
        XCTAssertEqual(WeightTrend.trend(on: day(9), in: points, calendar: calendar), points.last?.trend)
    }
}
