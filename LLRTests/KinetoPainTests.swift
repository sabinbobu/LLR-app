import XCTest
@testable import LLR

final class KinetoPainTests: XCTestCase {
    func testTwoPointRiseFlags() {
        XCTAssertTrue(KinetoPain.worsened(before: 3, after: 5))
        XCTAssertFalse(KinetoPain.worsened(before: 3, after: 4), "one point is within noise, per Ostelo 2008")
    }

    func testMissingScoresNeverFlag() {
        XCTAssertFalse(KinetoPain.worsened(before: nil, after: 8))
        XCTAssertFalse(KinetoPain.worsened(before: 3, after: nil))
    }

    func testEitherRegionCanTriggerTheFlag() {
        XCTAssertTrue(KinetoPain.shouldFlag(backBefore: 2, backAfter: 5, legBefore: 0, legAfter: 0, symptomsSpread: false))
        XCTAssertTrue(KinetoPain.shouldFlag(backBefore: 0, backAfter: 0, legBefore: 2, legAfter: 5, symptomsSpread: false))
        XCTAssertFalse(KinetoPain.shouldFlag(backBefore: 2, backAfter: 3, legBefore: 2, legAfter: 3, symptomsSpread: false))
    }

    func testSpreadFlagsOnItsOwnEvenWithFlatScores() {
        XCTAssertTrue(KinetoPain.shouldFlag(backBefore: 3, backAfter: 3, legBefore: 0, legAfter: 0, symptomsSpread: true))
    }
}

final class KinetoDirectionPreferenceTests: XCTestCase {
    func testOnlyTheOppositeSingleDirectionWarns() {
        XCTAssertTrue(KinetoDirectionPreference.matchesFlexion.warns(for: .extension))
        XCTAssertFalse(KinetoDirectionPreference.matchesFlexion.warns(for: .flexion))
        XCTAssertFalse(KinetoDirectionPreference.matchesFlexion.warns(for: .neutral))
        XCTAssertFalse(KinetoDirectionPreference.matchesFlexion.warns(for: .rotation))
        XCTAssertTrue(KinetoDirectionPreference.matchesExtension.warns(for: .flexion))
    }

    func testUnsetOrNoPreferenceNeverWarns() {
        for direction: KinetoCatalog.Direction in [.flexion, .extension, .rotation, .neutral] {
            XCTAssertFalse(KinetoDirectionPreference.notAssessed.warns(for: direction))
            XCTAssertFalse(KinetoDirectionPreference.noPreference.warns(for: direction))
        }
    }
}

final class KinetoLevelDoseTextTests: XCTestCase {
    private func level(sets: Int? = nil, reps: Int? = nil, seconds: Int? = nil) -> KinetoCatalog.Level {
        // Decoded via JSON since Level's memberwise init isn't public API outside the model file.
        let json = """
        {"Label":"L","Sets":\(sets.map(String.init) ?? "null"),"Reps":\(reps.map(String.init) ?? "null"),
         "DurationSeconds":\(seconds.map(String.init) ?? "null"),"Notes":null}
        """
        return try! JSONDecoder().decode(KinetoCatalog.Level.self, from: Data(json.utf8))
    }

    func testSetsAndHoldNoReps() {
        XCTAssertEqual(level(sets: 5, seconds: 15).doseText, "5 × 15 s")
    }

    func testSetsRepsAndHold() {
        XCTAssertEqual(level(sets: 2, reps: 10, seconds: 2).doseText, "2 × 10 × 2 s")
    }

    func testSetsAndRepsOnly() {
        XCTAssertEqual(level(sets: 1, reps: 15).doseText, "1 × 15")
    }

    func testDurationOnlyUsesMinutes() {
        XCTAssertEqual(level(seconds: 1200).doseText, "20m")
    }

    func testNoDoseAtAllDefersToThePhysio() {
        XCTAssertEqual(level().doseText, "Set by your physiotherapist")
    }
}
