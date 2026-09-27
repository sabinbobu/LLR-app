import XCTest
@testable import LLR

/// Points are polygon centroids from body_map.json, so they sit inside their muscle.
final class BodyMapHitTestTests: XCTestCase {
    func testChestAndWaist() {
        XCTAssertEqual(BodyMapHitTest.measurement(at: CGPoint(x: 0.393, y: 0.249), side: .anterior), .chest)
        XCTAssertEqual(BodyMapHitTest.measurement(at: CGPoint(x: 0.45, y: 0.396), side: .anterior), .waist)
    }

    func testFrontViewMirrorsLeftAndRight() {
        // Facing the viewer, the figure's right arm is on screen-left.
        XCTAssertEqual(BodyMapHitTest.measurement(at: CGPoint(x: 0.225, y: 0.304), side: .anterior), .rightBicep)
        XCTAssertEqual(BodyMapHitTest.measurement(at: CGPoint(x: 0.769, y: 0.305), side: .anterior), .leftBicep)
    }

    func testBackViewGlutesAreHips() {
        XCTAssertEqual(BodyMapHitTest.measurement(at: CGPoint(x: 0.388, y: 0.574), side: .posterior), .hips)
    }

    func testEmptySpaceIsNil() {
        XCTAssertNil(BodyMapHitTest.measurement(at: CGPoint(x: 0.03, y: 0.97), side: .anterior))
    }
}
