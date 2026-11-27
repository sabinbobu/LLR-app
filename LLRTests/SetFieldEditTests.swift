import XCTest
@testable import LLR

final class SetFieldEditTests: XCTestCase {
    /// Feeds the field's successive contents through one edit, as typing and deleting would.
    private func type(_ texts: [String], overWeight kg: Double, unit: WeightUnit = .kg,
                      edit: inout SetFieldEdit<Double>) -> Double {
        texts.reduce(kg) { edit.weightKg($1, current: $0, unit: unit) }
    }

    private func type(_ texts: [String], overWeight kg: Double) -> Double {
        var edit = SetFieldEdit<Double>()
        return type(texts, overWeight: kg, edit: &edit)
    }

    func testShowingTheStoredWeightLeavesItExact() {
        XCTAssertEqual(type([WeightUnit.kg.format(kg: 61.25)], overWeight: 61.25), 61.25)
    }

    func testShowingAStoredWeightInEitherUnitNeverDriftsIt() {
        let stored = (1...200).map { Double($0) * 1.25 }
            + (1...200).map { WeightUnit.lbs.toKg(Double($0) * 2.5) }
        var drifted: [String] = []
        for unit in WeightUnit.allCases {
            for kg in stored {
                var edit = SetFieldEdit<Double>()
                let result = edit.weightKg(unit.format(kg: kg), current: kg, unit: unit)
                if result != kg { drifted.append("\(kg) shown in \(unit.rawValue) became \(result)") }
            }
        }
        XCTAssertTrue(drifted.isEmpty, "\(drifted.count) drifted, first: \(drifted.first ?? "")")
    }

    func testTypingANewWeightStoresIt() {
        XCTAssertEqual(type(["6", "62", "62.", "62.5"], overWeight: 61.25), 62.5)
        XCTAssertEqual(type(["6", "62", "62,", "62,5"], overWeight: 61.25), 62.5)
    }

    /// The suggestion reads "61.3", but someone who types it themselves means 61.3.
    func testTypingTheRoundedValueStoresWhatWasTyped() {
        XCTAssertEqual(type(["6", "61", "61.", "61.3"], overWeight: 61.25), 61.3)
    }

    func testUnreadableTextKeepsTheWeight() {
        XCTAssertEqual(type([","], overWeight: 130), 130)
    }

    func testClearingTheFieldRestoresTheWeight() {
        XCTAssertEqual(type(["1", "10", "100", "10", "1", ""], overWeight: 130), 130)
    }

    func testClearingAnUnsetWeightReturnsToZero() {
        XCTAssertEqual(type(["8", "80", "8", ""], overWeight: 0), 0)
    }

    func testClearingRestoresReps() {
        var edit = SetFieldEdit<Int>()
        let reps = ["1", "12", "1", ""].reduce(5) { edit.reps($1, current: $0) }
        XCTAssertEqual(reps, 5)
    }

    func testClearingRestoresTheHold() {
        var edit = SetFieldEdit<Int?>()
        let seconds = ["4", "45", "4", ""].reduce(Optional(300)) { edit.holdSeconds($1, current: $0) }
        XCTAssertEqual(seconds, 300)
    }

    func testAZeroHoldIsNeverStored() {
        var edit = SetFieldEdit<Int?>()
        XCTAssertEqual(edit.holdSeconds("0", current: 300), 300)
    }

    func testResetMakesTheCommittedValueTheOneToRestore() {
        var edit = SetFieldEdit<Double>()
        let committed = type(["1", "10", "100"], overWeight: 130, edit: &edit)
        edit.reset()
        XCTAssertEqual(type(["1", ""], overWeight: committed, edit: &edit), 100)
    }

    func testShowingAPlannedWeightLeavesItExact() {
        XCTAssertEqual(PlannedSetField.weightKg("61.3", current: 61.25, unit: .kg), 61.25)
    }

    func testBlankPlannedWeightStaysBlank() {
        XCTAssertNil(PlannedSetField.weightKg("", current: nil, unit: .kg))
        XCTAssertNil(PlannedSetField.weightKg("", current: 60, unit: .kg))
    }
}
