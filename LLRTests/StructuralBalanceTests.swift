import XCTest
@testable import LLR

final class StructuralBalanceTests: XCTestCase {
    private typealias Balance = StructuralBalance

    private let upper = Balance.Group(
        id: "upper", title: "Upper Body",
        reference: Balance.Lift(id: "bench", name: "Bench Press", exercises: ["Bench Press (Barbell)"], targetPct: 100),
        lifts: [
            Balance.Lift(id: "incline", name: "Incline Bench Press", exercises: ["Incline Bench Press (Barbell)"], targetPct: 80),
            Balance.Lift(id: "closeGrip", name: "Close-Grip Bench Press", exercises: ["Bench Press - Close Grip (Barbell)"], targetPct: 90),
            Balance.Lift(id: "military", name: "Military Press", exercises: ["Standing Military Press (Barbell)", "Overhead Press (Barbell)"], targetPct: 60),
            Balance.Lift(
                id: "chin", name: "Supinated Chin-Up", exercises: ["Chin Up", "Chin Up (Weighted)", "Chin Up (Assisted)"],
                targetPct: 90, includesBodyweight: true
            ),
        ]
    )

    private func single(_ kg: Double) -> [SetValue] { [SetValue(weightKg: kg, reps: 1)] }

    private func row(_ id: String, in rows: [Balance.Row]) throws -> Balance.Row {
        try XCTUnwrap(rows.first { $0.lift.id == id })
    }

    func testAtOrAboveTheTargetIsBalancedWithinFivePointsIsBorderlineBelowThatIsWeak() {
        XCTAssertEqual(Balance.classify(actualPct: 80, targetPct: 80), .balanced)
        XCTAssertEqual(Balance.classify(actualPct: 96, targetPct: 80), .balanced)
        XCTAssertEqual(Balance.classify(actualPct: 79.9, targetPct: 80), .borderline)
        XCTAssertEqual(Balance.classify(actualPct: 75, targetPct: 80), .borderline)
        XCTAssertEqual(Balance.classify(actualPct: 74.9, targetPct: 80), .weak)
        XCTAssertEqual(Balance.classify(actualPct: nil, targetPct: 80), .noData)
    }

    func testEachLiftIsScoredAsAPercentOfTheReferenceLift() throws {
        let history = [
            "Bench Press (Barbell)": single(100),
            "Incline Bench Press (Barbell)": single(85),
            "Bench Press - Close Grip (Barbell)": single(87),
            "Overhead Press (Barbell)": single(50),
        ]
        let result = Balance.evaluate(upper, history: history, bodyweightKg: nil)
        XCTAssertEqual(result.reference.actualPct, 100)
        XCTAssertEqual(result.reference.status, .balanced)
        XCTAssertEqual(try row("incline", in: result.rows).actualPct ?? 0, 85, accuracy: 1e-9)
        XCTAssertEqual(try row("incline", in: result.rows).status, .balanced)
        XCTAssertEqual(try row("closeGrip", in: result.rows).status, .borderline)
        XCTAssertEqual(try row("military", in: result.rows).status, .weak)
        XCTAssertEqual(try row("military", in: result.rows).exercise, "Overhead Press (Barbell)")
    }

    func testTheBestEstimateAcrossWorkingSetsAndMappedExercisesCounts() throws {
        let history = [
            // 80 × 10 → 80 × (1 + 10/30) = 106.67; the 200 kg warm-up must not count.
            "Bench Press (Barbell)": [SetValue(weightKg: 80, reps: 10), SetValue(weightKg: 200, reps: 1, kind: .warmup)],
            "Standing Military Press (Barbell)": single(60),
            "Overhead Press (Barbell)": single(64),
        ]
        let result = Balance.evaluate(upper, history: history, bodyweightKg: nil)
        XCTAssertEqual(result.reference.oneRepMaxKg ?? 0, 80 * (1 + 10.0 / 30), accuracy: 1e-9)
        let military = try row("military", in: result.rows)
        XCTAssertEqual(military.oneRepMaxKg, 64)
        XCTAssertEqual(military.actualPct ?? 0, 64 / (80 * (1 + 10.0 / 30)) * 100, accuracy: 1e-9)
    }

    func testAChinUpMovesTheLifterPlusTheBelt() throws {
        let history = ["Bench Press (Barbell)": single(100), "Chin Up (Weighted)": single(10)]
        let chin = try row("chin", in: Balance.evaluate(upper, history: history, bodyweightKg: 80).rows)
        XCTAssertEqual(chin.oneRepMaxKg, 90)
        XCTAssertEqual(chin.status, .balanced)
    }

    func testAnUnloadedChinUpIsBodyweightForReps() throws {
        // 80 kg × 6 → 80 × 1.2 = 96.
        let history = ["Bench Press (Barbell)": single(100), "Chin Up": [SetValue(weightKg: 0, reps: 6)]]
        let chin = try row("chin", in: Balance.evaluate(upper, history: history, bodyweightKg: 80).rows)
        XCTAssertEqual(chin.oneRepMaxKg ?? 0, 96, accuracy: 1e-9)
    }

    func testAnAssistedChinUpMovesTheLifterMinusTheHelp() throws {
        let history = [
            "Bench Press (Barbell)": single(100),
            // 0 is "no help typed in" and help at or above body weight moved nothing: neither is a lift.
            "Chin Up (Assisted)": [SetValue(weightKg: 20, reps: 1), SetValue(weightKg: 0, reps: 1), SetValue(weightKg: 80, reps: 1)],
        ]
        let chin = try row("chin", in: Balance.evaluate(upper, history: history, bodyweightKg: 80).rows)
        XCTAssertEqual(chin.oneRepMaxKg, 60)
        XCTAssertEqual(chin.status, .weak)
    }

    func testABodyweightLiftWaitsForABodyWeight() throws {
        let history = ["Bench Press (Barbell)": single(100), "Chin Up": [SetValue(weightKg: 0, reps: 6)]]
        let chin = try row("chin", in: Balance.evaluate(upper, history: history, bodyweightKg: nil).rows)
        XCTAssertEqual(chin.status, .noData)
        XCTAssertTrue(chin.needsBodyweight)
        XCTAssertFalse(try row("incline", in: Balance.evaluate(upper, history: history, bodyweightKg: nil).rows).needsBodyweight)
    }

    func testWithoutTheReferenceLiftNothingIsScored() throws {
        let result = Balance.evaluate(upper, history: ["Incline Bench Press (Barbell)": single(85)], bodyweightKg: 80)
        XCTAssertEqual(result.reference.status, .noData)
        let incline = try row("incline", in: result.rows)
        XCTAssertEqual(incline.oneRepMaxKg, 85)
        XCTAssertNil(incline.actualPct)
        XCTAssertEqual(incline.status, .noData)
    }

    func testThibaudeauTableMatchesTheArticle() throws {
        let template = try XCTUnwrap(Balance.templates.first { $0.id == "thibaudeau" })
        func table(_ id: String) throws -> [String: Double] {
            let group = try XCTUnwrap(template.groups.first { $0.id == id })
            return Dictionary(uniqueKeysWithValues: group.lifts.map { ($0.name, $0.targetPct) })
        }
        XCTAssertEqual(try table("upper"), [
            "Close-Grip Bench Press": 90, "Push Press": 85, "Incline Bench Press": 80, "Military Press": 60,
            "Weighted Dip": 105, "Supinated Chin-Up": 90, "Chest-Supported Row": 70, "Preacher Curl": 40,
            "Standing Reverse Curl": 35,
        ])
        XCTAssertEqual(try table("lower"), ["Front Squat": 85, "Deadlift": 120])
        XCTAssertEqual(try table("whole"), ["Bench Press": 75, "Deadlift": 120, "Military Press": 45])
    }

    func testPoliquinTableMatchesTheArticle() throws {
        let template = try XCTUnwrap(Balance.templates.first { $0.id == "poliquin" })
        let group = try XCTUnwrap(template.groups.first)
        XCTAssertEqual(group.reference.name, "Close-Grip Bench Press")
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: group.lifts.map { ($0.name, $0.targetPct) }), [
            "Incline Barbell Press": 83, "Supinated Chin-Up": 81, "Scott Barbell Curl": 46, "Standing Reverse Curl": 30,
        ])
    }

    func testEveryMappedExerciseExistsInTheLibraryAndIdsAreUnique() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "exercises", withExtension: "json"))
        let library = Set(try ExerciseLibrary.parseSeeds(Data(contentsOf: url)).map(\.name))
        for template in Balance.templates {
            XCTAssertNotNil(template.url, template.id)
            for group in template.groups {
                let lifts = [group.reference] + group.lifts
                XCTAssertEqual(Set(lifts.map(\.id)).count, lifts.count, "\(template.id)/\(group.id)")
                for name in lifts.flatMap(\.exercises) {
                    XCTAssertTrue(library.contains(name), "\(name) is not in the library")
                }
            }
        }
    }
}
