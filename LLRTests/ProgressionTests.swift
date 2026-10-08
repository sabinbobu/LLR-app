import XCTest
@testable import LLR

/// The single-session shape these tests were written against, kept so they still pin double progression.
private extension Progression {
    static func config(_ range: ClosedRange<Int>, _ incrementKg: Double) -> Config {
        Config(rule: .double, range: range, incrementKg: incrementKg)
    }

    static func plan(previous: [SetValue], range: ClosedRange<Int>, incrementKg: Double) -> Plan? {
        plan(history: [Session(date: .distantPast, sets: previous)], config: config(range, incrementKg))
    }

    static func targets(previous: [SetValue], range: ClosedRange<Int>, incrementKg: Double) -> [SetValue]? {
        targets(history: [Session(date: .distantPast, sets: previous)], config: config(range, incrementKg))
    }

    static func prefill(index: Int, previous: [SetValue], currentLast: SetValue?, range: ClosedRange<Int>?, incrementKg: Double) -> SetValue? {
        prefill(
            index: index, history: [Session(date: .distantPast, sets: previous)], currentLast: currentLast,
            config: range.map { config($0, incrementKg) }
        )
    }
}

final class ProgressionTests: XCTestCase {
    private func set(_ kg: Double, _ reps: Int, _ kind: SetKind = .normal) -> SetValue {
        SetValue(weightKg: kg, reps: reps, kind: kind)
    }

    func testBelowTopAddsOneRepAtSameWeightCappedAtTop() {
        let previous = [set(40, 10, .warmup), set(80, 10), set(80, 9), set(80, 12)]
        let targets = Progression.targets(previous: previous, range: 8...12, incrementKg: 2.5)
        XCTAssertEqual(targets, [set(40, 10, .warmup), set(80, 11), set(80, 10), set(80, 12)])
    }

    func testEveryWorkingSetAtTopAddsLoadAndResetsReps() {
        let previous = [set(40, 10, .warmup), set(80, 12), set(80, 12, .failure), set(60, 15, .drop)]
        let targets = Progression.targets(previous: previous, range: 8...12, incrementKg: 2.5)
        XCTAssertEqual(targets, [set(40, 10, .warmup), set(82.5, 8), set(82.5, 8, .failure), set(60, 15, .drop)])
        XCTAssertEqual(Progression.plan(previous: previous, range: 8...12, incrementKg: 2.5), .addLoad(kg: 2.5))
    }

    func testSetAlreadyPastTheTopIsNeverAskedForLess() {
        let targets = Progression.targets(previous: [set(80, 14), set(80, 9)], range: 8...12, incrementKg: 2.5)
        XCTAssertEqual(targets, [set(80, 14), set(80, 10)])
    }

    func testBodyweightOnlyEverAddsReps() {
        let targets = Progression.targets(previous: [set(0, 12), set(0, 15)], range: 8...12, incrementKg: 2.5)
        XCTAssertEqual(targets, [set(0, 13), set(0, 16)])
    }

    func testNothingToBuildOnFallsBackToLastSession() {
        let warmupsOnly = [set(40, 10, .warmup)]
        XCTAssertNil(Progression.targets(previous: warmupsOnly, range: 8...12, incrementKg: 2.5))
        XCTAssertNil(Progression.plan(previous: [], range: 8...12, incrementKg: 2.5))
        XCTAssertEqual(
            Progression.prefill(index: 0, previous: warmupsOnly, currentLast: nil, range: 8...12, incrementKg: 2.5),
            set(40, 10, .warmup)
        )
    }

    func testNoRangeIsExactlyTheOldPrefill() {
        let previous = [set(80, 12), set(80, 12)]
        for index in 0..<3 {
            XCTAssertEqual(
                Progression.prefill(index: index, previous: previous, currentLast: set(85, 6), range: nil, incrementKg: 2.5),
                PreviousPerformance.prefill(index: index, previous: previous, currentLast: set(85, 6))
            )
        }
    }

    func testExtraSetBeyondLastSessionRepeatsTodaysLastSet() {
        let previous = [set(80, 12)]
        let extra = Progression.prefill(index: 1, previous: previous, currentLast: set(82.5, 8), range: 8...12, incrementKg: 2.5)
        XCTAssertEqual(extra, set(82.5, 8))
    }

    func testIncrementMatchesTheKit() {
        XCTAssertEqual(Progression.incrementKg(equipment: ["Barbell"], unit: .kg), 2.5)
        XCTAssertEqual(Progression.incrementKg(equipment: ["Dumbbell"], unit: .kg), 2)
        XCTAssertEqual(Progression.incrementKg(equipment: ["Kettlebell"], unit: .kg), 4)
        XCTAssertEqual(Progression.incrementKg(equipment: [], unit: .kg), 2.5)
        XCTAssertEqual(Progression.incrementKg(equipment: ["Barbell"], unit: .lbs), 5 * WeightUnit.kgPerLb, accuracy: 1e-9)
    }

    func testPoundsStepLandsOnWholePounds() {
        let previous = [set(WeightUnit.lbs.toKg(135), 12)]
        let step = Progression.incrementKg(equipment: ["Barbell"], unit: .lbs)
        let target = Progression.targets(previous: previous, range: 8...12, incrementKg: step)?.first
        XCTAssertEqual(WeightUnit.lbs.format(kg: target?.weightKg ?? 0), "140")
    }

    func testExerciseRepRangeRoundTripsAndRejectsInverted() {
        let exercise = Exercise(name: "Squat (Barbell)", muscleGroup: "Quadriceps")
        XCTAssertNil(exercise.repRange)
        exercise.repRange = 5...8
        XCTAssertEqual(exercise.repRange, 5...8)
        exercise.repRangeMin = 10
        XCTAssertNil(exercise.repRange)
        exercise.repRange = nil
        XCTAssertNil(exercise.repRangeMin)
    }
}
