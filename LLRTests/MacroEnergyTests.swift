import XCTest
@testable import LLR

final class MacroEnergyTests: XCTestCase {
    func testAtwaterFactors() {
        XCTAssertEqual(MacroEnergy.kcal(proteinG: 30, carbsG: 50, fatG: 10), 410)
    }

    func testRoundsToWholeCalories() {
        XCTAssertEqual(MacroEnergy.kcal(proteinG: 10.3, carbsG: 0, fatG: 0), 41)
    }

    func testNoMacrosIsZero() {
        XCTAssertEqual(MacroEnergy.kcal(proteinG: 0, carbsG: 0, fatG: 0), 0)
    }
}
