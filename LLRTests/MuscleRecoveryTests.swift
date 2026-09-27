import XCTest
@testable import LLR

final class MuscleRecoveryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func entry(_ muscle: String, secondary: [String] = [], hoursAgo: Double, name: String = "Bench Press") -> MuscleRecovery.Entry {
        MuscleRecovery.Entry(exerciseName: name, muscle: muscle, secondaryMuscles: secondary, completedAt: now.addingTimeInterval(-hoursAgo * 3600))
    }

    func testNoHistoryIsFullyRecovered() {
        let statuses = MuscleRecovery.statuses(for: [], now: now)
        XCTAssertEqual(statuses[.chest]?.percent, 100)
        XCTAssertNil(statuses[.chest]?.lastTrained)
    }

    func testTenSetsRightNowFullyFatiguesTheMuscle() throws {
        let entries = (0..<10).map { _ in entry("Chest", hoursAgo: 0) }
        let statuses = MuscleRecovery.statuses(for: entries, now: now)
        XCTAssertEqual(try XCTUnwrap(statuses[.chest]?.percent), 0, accuracy: 0.01)
    }

    func testRecoveryIsHalfwayAtHalfTheWindow() throws {
        // Chest uses the 72h window; 10 sets 36h ago should read 50%.
        let entries = (0..<10).map { _ in entry("Chest", hoursAgo: 36) }
        let statuses = MuscleRecovery.statuses(for: entries, now: now)
        XCTAssertEqual(try XCTUnwrap(statuses[.chest]?.percent), 50, accuracy: 0.5)
    }

    func testFullyRecoveredOncePastTheWindow() {
        let entries = (0..<10).map { _ in entry("Chest", hoursAgo: 73) }
        let statuses = MuscleRecovery.statuses(for: entries, now: now)
        XCTAssertEqual(statuses[.chest]?.percent, 100)
    }

    func testSecondaryMusclesCountAtHalfLoad() throws {
        // 20 sets as a secondary == 10 as a primary: both fully fatigue the muscle.
        let entries = (0..<20).map { _ in entry("Chest", secondary: ["Triceps"], hoursAgo: 0) }
        let statuses = MuscleRecovery.statuses(for: entries, now: now)
        XCTAssertEqual(try XCTUnwrap(statuses[.triceps]?.percent), 0, accuracy: 0.01)
    }

    func testFullBodyPrimaryContributesNothingButItsSecondariesStillCount() throws {
        let entries = (0..<10).map { _ in entry("Full Body", secondary: ["Chest"], hoursAgo: 0) }
        let statuses = MuscleRecovery.statuses(for: entries, now: now)
        XCTAssertNil(statuses[.fullBody], "Full Body isn't trainable, so it has no status at all")
        XCTAssertEqual(
            try XCTUnwrap(statuses[.chest]?.percent), 50, accuracy: 0.01,
            "10 sets at the 0.5 secondary weight is half the fatigue of 10 primary sets"
        )
    }

    func test48HourWindowForANonListedMuscle() throws {
        // Biceps isn't in the long-window set, so it clears in 48h, not 72h.
        let entries = (0..<10).map { _ in entry("Biceps", hoursAgo: 24) }
        let statuses = MuscleRecovery.statuses(for: entries, now: now)
        XCTAssertEqual(try XCTUnwrap(statuses[.biceps]?.percent), 50, accuracy: 0.5)
    }

    func testUnknownMuscleStringsAreIgnored() {
        let entries = [entry("Not A Real Muscle", hoursAgo: 0)]
        // Must not crash, and no trainable muscle should be affected.
        let statuses = MuscleRecovery.statuses(for: entries, now: now)
        XCTAssertEqual(MuscleRecovery.overallPercent(statuses), 100)
    }

    func testLastTrainedTracksTheMostRecentContributingSet() {
        let entries = [
            entry("Chest", hoursAgo: 10, name: "Incline Bench Press"),
            entry("Chest", hoursAgo: 2, name: "Bench Press"),
        ]
        let statuses = MuscleRecovery.statuses(for: entries, now: now)
        XCTAssertEqual(statuses[.chest]?.lastExerciseName, "Bench Press")
        XCTAssertEqual(statuses[.chest]?.lastTrained, now.addingTimeInterval(-2 * 3600))
    }

    func testOverallPercentIsTheMeanAcrossAllTrainableMuscles() {
        let statuses = MuscleRecovery.statuses(for: [], now: now)
        XCTAssertEqual(MuscleRecovery.overallPercent(statuses), 100)
    }
}
