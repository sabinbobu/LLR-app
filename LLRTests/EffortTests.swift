import XCTest
@testable import LLR

final class EffortTests: XCTestCase {
    func testPresetsLandOnTheirOwnBandAndInBetweenValuesTakeTheOneTheySitIn() {
        XCTAssertEqual(Effort.bands.map { Effort.bandIndex(for: $0.rir) }, [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(Effort.bandIndex(for: 1.5), 2)
        XCTAssertEqual(Effort.bandIndex(for: 2.5), 3)
        XCTAssertEqual(Effort.bandIndex(for: 7), 5)
    }

    func testRPEIsTenMinusRepsInReserve() {
        XCTAssertEqual(Effort.rir(fromRPE: 8), 2)
        XCTAssertEqual(Effort.rir(fromRPE: 9.5), 0.5)
        XCTAssertEqual(Effort.rir(fromRPE: 10), 0)
        XCTAssertNil(Effort.rir(fromRPE: 0), "a blank or zero column is not a rating")
        XCTAssertNil(Effort.rir(fromRPE: 11))
    }

    func testTextFollowsTheChosenScale() {
        XCTAssertEqual(Effort.text(rir: 2, scale: .rir), "2")
        XCTAssertEqual(Effort.text(rir: 2, scale: .rpe), "8")
        XCTAssertEqual(Effort.text(rir: 0.5, scale: .rir), "0.5")
        XCTAssertEqual(Effort.text(rir: 0.5, scale: .rpe), "9.5")
        XCTAssertEqual(Effort.text(rir: 0, scale: .rpe), "10")
    }

    func testTopBucketReadsAsFourPlusInRIROnly() {
        XCTAssertEqual(Effort.text(rir: 4, scale: .rir), "4+")
        XCTAssertEqual(Effort.text(rir: 6, scale: .rir), "4+")
        XCTAssertEqual(Effort.text(rir: 4, scale: .rpe), "6")
    }

    func testHardMeansThreeOrFewerInReserveAndUnratedIsNeverHard() {
        XCTAssertTrue(Effort.isHard(0))
        XCTAssertTrue(Effort.isHard(3))
        XCTAssertFalse(Effort.isHard(3.5))
        XCTAssertFalse(Effort.isHard(nil))
    }
}
