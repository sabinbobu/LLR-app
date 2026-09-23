import XCTest
@testable import LLR

final class PersonalRecordsTests: XCTestCase {
    private let history = [SetValue(weightKg: 100, reps: 5), SetValue(weightKg: 90, reps: 8)]

    func testHeavierSetIsWeightAnd1RMRecord() {
        // 105×5 = 525 volume, below the 90×8 = 720 already on record.
        let kinds = PersonalRecords.kinds(for: SetValue(weightKg: 105, reps: 5), history: history, earlierToday: [])
        XCTAssertEqual(kinds, [.weight, .oneRepMax])
    }

    func testAllThreeRecordsAtOnce() {
        let kinds = PersonalRecords.kinds(for: SetValue(weightKg: 105, reps: 8), history: history, earlierToday: [])
        XCTAssertEqual(kinds, [.weight, .oneRepMax, .setVolume])
    }

    func testMoreRepsAtLowerWeightCanBeVolumeOnly() {
        // 80×10 = 800 volume > 720; 1RM 106.7 < 116.7; weight 80 < 100.
        let kinds = PersonalRecords.kinds(for: SetValue(weightKg: 80, reps: 10), history: history, earlierToday: [])
        XCTAssertEqual(kinds, [.setVolume])
    }

    func testEqualLiftIsNotARecord() {
        XCTAssertTrue(PersonalRecords.kinds(for: SetValue(weightKg: 100, reps: 5), history: history, earlierToday: []).isEmpty)
    }

    func testFirstEverSessionHasNoRecords() {
        XCTAssertTrue(PersonalRecords.kinds(for: SetValue(weightKg: 200, reps: 5), history: [], earlierToday: []).isEmpty)
    }

    func testWarmupNeverARecord() {
        let warmup = SetValue(weightKg: 300, reps: 5, kind: .warmup)
        XCTAssertTrue(PersonalRecords.kinds(for: warmup, history: history, earlierToday: []).isEmpty)
    }

    func testWarmupHistoryDoesNotCountAsBaseline() {
        let warmupOnly = [SetValue(weightKg: 40, reps: 10, kind: .warmup)]
        XCTAssertTrue(PersonalRecords.kinds(for: SetValue(weightKg: 60, reps: 5), history: warmupOnly, earlierToday: []).isEmpty)
    }

    func testEarlierSetTodayRaisesTheBar() {
        let earlier = [SetValue(weightKg: 110, reps: 5)]
        let kinds = PersonalRecords.kinds(for: SetValue(weightKg: 105, reps: 5), history: history, earlierToday: earlier)
        XCTAssertTrue(kinds.isEmpty)
    }
}
