import XCTest
@testable import LLR

final class KinetoGateStateTests: XCTestCase {
    func testClearedOnlyAtOrAboveTheCatalogVersion() {
        XCTAssertFalse(KinetoCatalog.isCleared(0, catalogVersion: 3))
        XCTAssertFalse(KinetoCatalog.isCleared(2, catalogVersion: 3))
        XCTAssertTrue(KinetoCatalog.isCleared(3, catalogVersion: 3))
        XCTAssertTrue(KinetoCatalog.isCleared(4, catalogVersion: 3))
    }

    func testUnreadableCatalogNeverCountsAsCleared() {
        XCTAssertFalse(KinetoCatalog.isCleared(0, catalogVersion: 0))
        XCTAssertFalse(KinetoCatalog.isCleared(5, catalogVersion: 0))
    }

    func testBundledCatalogLoadsInTheApp() {
        XCTAssertGreaterThan(KinetoCatalog.version, 0, "the bundle must carry kineto_exercises.json")
        XCTAssertFalse(KinetoCatalog.exercises.isEmpty)
    }
}
