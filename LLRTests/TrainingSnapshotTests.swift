import XCTest
@testable import LLR

final class TrainingSnapshotTests: XCTestCase {
    func testEncodesAndDecodesRoundTrip() throws {
        let original = TrainingSnapshot(
            streak: 4,
            trainedDaysThisMonth: [Date(timeIntervalSince1970: 1_700_000_000), Date(timeIntervalSince1970: 1_700_086_400)],
            generatedAt: Date(timeIntervalSince1970: 1_700_100_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TrainingSnapshot.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testReadReturnsNilWithNoContainerOrNoFile() {
        // Tests run hosted in the app, which owns the App Group and writes a real snapshot on launch,
        // so the shared file can't be relied on to be absent; exercise the fallbacks explicitly.
        XCTAssertNil(TrainingSnapshot.read(from: nil))
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        XCTAssertNil(TrainingSnapshot.read(from: missing))
    }

    func testStreakLapsesOnceAWholeWeekPassesUntrained() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        let monday = Date(timeIntervalSince1970: 1_699_833_600) // Mon 13 Nov 2023
        let snapshot = TrainingSnapshot(streak: 5, trainedDaysThisMonth: [monday], generatedAt: monday, lastTrainedAt: monday)

        XCTAssertEqual(snapshot.streak(asOf: monday.addingTimeInterval(3 * 86_400), calendar: calendar), 5)
        // Next week, untrained so far: the week isn't over, the streak holds.
        XCTAssertEqual(snapshot.streak(asOf: monday.addingTimeInterval(9 * 86_400), calendar: calendar), 5)
        // A full week went by with nothing: the widget must not keep showing 5.
        XCTAssertEqual(snapshot.streak(asOf: monday.addingTimeInterval(15 * 86_400), calendar: calendar), 0)
    }

    func testSnapshotWrittenBeforeLastTrainedExistedStillDecodes() throws {
        let old = Data(#"{"streak":3,"trainedDaysThisMonth":[],"generatedAt":0}"#.utf8)
        let decoded = try JSONDecoder().decode(TrainingSnapshot.self, from: old)
        XCTAssertEqual(decoded.streak(asOf: .now), 3, "no date to judge by: show what was stored")
    }

    func testWriteThenReadRoundTripsThroughAFile() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let snapshot = TrainingSnapshot(streak: 2, trainedDaysThisMonth: [], generatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        snapshot.write(to: url)
        XCTAssertEqual(TrainingSnapshot.read(from: url), snapshot)
    }

    func testBuildingFromTrainingCalendarMatchesItsOwnOutputs() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let starts = [now, now.addingTimeInterval(-7 * 86_400)]

        let snapshot = TrainingSnapshot(
            streak: TrainingCalendar.weekStreak(workouts: starts, now: now, calendar: calendar),
            trainedDaysThisMonth: Array(TrainingCalendar.trainedDays(in: now, workouts: starts, calendar: calendar)),
            generatedAt: now
        )
        XCTAssertEqual(snapshot.streak, TrainingCalendar.weekStreak(workouts: starts, now: now, calendar: calendar))
        XCTAssertEqual(Set(snapshot.trainedDaysThisMonth), TrainingCalendar.trainedDays(in: now, workouts: starts, calendar: calendar))
    }
}
