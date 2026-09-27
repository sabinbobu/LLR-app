import XCTest
@testable import LLR

final class WeeklyVolumeTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }()
    // Monday 2026-09-21 00:00 UTC.
    private let weekStart = Date(timeIntervalSince1970: 1_789_948_800)

    private func entry(_ muscle: String, secondary: [String] = [], at date: Date) -> MuscleRecovery.Entry {
        MuscleRecovery.Entry(exerciseName: "Test", muscle: muscle, secondaryMuscles: secondary, completedAt: date)
    }

    private func sets(_ entries: [MuscleRecovery.Entry]) -> [MuscleGroup.RadarAxis: Double] {
        WeeklyVolume.sets(entries, week: weekStart.addingTimeInterval(3 * 86_400), calendar: calendar)
    }

    func testBandBoundaries() {
        XCTAssertEqual(WeeklyVolume.band(for: 0), .none)
        XCTAssertEqual(WeeklyVolume.band(for: 4.5), .low)
        XCTAssertEqual(WeeklyVolume.band(for: 5), .building)
        XCTAssertEqual(WeeklyVolume.band(for: 9.5), .building)
        XCTAssertEqual(WeeklyVolume.band(for: 10), .target)
        XCTAssertEqual(WeeklyVolume.band(for: 20), .target)
        XCTAssertEqual(WeeklyVolume.band(for: 20.5), .high)
    }

    func testPrimaryCountsOneSecondaryCountsHalf() {
        let day = weekStart.addingTimeInterval(86_400)
        let result = sets((0..<3).map { _ in entry("Chest", secondary: ["Triceps", "Shoulders"], at: day) })
        XCTAssertEqual(result[.chest], 3)
        XCTAssertEqual(result[.triceps], 1.5)
        XCTAssertEqual(result[.shoulders], 1.5)
    }

    func testMusclesSharingAnAxisCountOncePerSet() {
        let result = sets([entry("Lats", secondary: ["Upper Back", "Biceps"], at: weekStart.addingTimeInterval(3600))])
        XCTAssertEqual(result[.back], 1)
        XCTAssertEqual(result[.biceps], 0.5)
    }

    func testOnlyTheRequestedWeekCounts() {
        let result = sets([
            entry("Chest", at: weekStart),
            entry("Chest", at: weekStart.addingTimeInterval(-1)),
            entry("Chest", at: weekStart.addingTimeInterval(7 * 86_400)),
        ])
        XCTAssertEqual(result[.chest], 1)
    }

    func testNonTrainableMusclesAreIgnored() {
        let result = sets([entry("Cardio", secondary: ["Full Body"], at: weekStart.addingTimeInterval(3600))])
        XCTAssertTrue(result.isEmpty)
    }
}
