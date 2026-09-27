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

    func testReadReturnsNilWithNoAppGroupContainerAvailable() {
        // The test target isn't a member of the App Group, so there's no container to read from —
        // this must degrade to nil, never crash, matching how a fresh install (no snapshot yet) behaves.
        XCTAssertNil(TrainingSnapshot.read())
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
