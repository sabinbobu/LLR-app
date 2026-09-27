import XCTest
@testable import LLR

final class BodyMapTests: XCTestCase {
    func testTheBundledDatasetParses() {
        XCTAssertFalse(BodyMapData.shared.anterior.isEmpty)
        XCTAssertFalse(BodyMapData.shared.posterior.isEmpty)
    }

    func testEveryPolygonHasAtLeastThreePoints() {
        for region in BodyMapData.shared.anterior + BodyMapData.shared.posterior {
            for polygon in region.polygons {
                XCTAssertGreaterThanOrEqual(polygon.count, 3, "\(region.muscle) has a degenerate polygon")
            }
        }
    }

    func testEveryTrainableMuscleHasAtLeastOnePolygonSomewhereOnTheMap() {
        let mapped = Set(
            (BodyMapData.shared.anterior + BodyMapData.shared.posterior)
                .flatMap { BodyMapData.muscleGroups(for: $0.muscle) }
        )
        for muscle in MuscleGroup.allCases where muscle.isTrainable {
            XCTAssertTrue(mapped.contains(muscle), "\(muscle.rawValue) has no drawable region")
        }
    }

    func testUnknownRegionNamesMapToNoMuscle() {
        XCTAssertEqual(BodyMapData.muscleGroups(for: "HEAD"), [])
        XCTAssertEqual(BodyMapData.muscleGroups(for: "NOT_A_REGION"), [])
    }
}
