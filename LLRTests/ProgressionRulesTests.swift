import XCTest
@testable import LLR

final class ProgressionRulesTests: XCTestCase {
    private func set(_ kg: Double, _ reps: Int, _ kind: SetKind = .normal) -> SetValue {
        SetValue(weightKg: kg, reps: reps, kind: kind)
    }

    /// Sessions one day apart, oldest first.
    private func history(_ sessions: [SetValue]...) -> [Session] {
        sessions.enumerated().map { Session(date: Date(timeIntervalSince1970: Double($0.offset) * 86_400), sets: $0.element) }
    }

    private func linear(_ reps: Int = 5, step: Double = 2.5, assisted: Bool = false) -> Progression.Config {
        Progression.Config(rule: .linear, range: reps...reps, incrementKg: step, assisted: assisted)
    }

    // MARK: Linear

    func testLinearAddsAStepWhenEverySetHitItsReps() {
        let past = history([set(40, 5, .warmup), set(100, 5), set(100, 5), set(100, 6)])
        XCTAssertEqual(Progression.plan(history: past, config: linear()), .addLoad(kg: 2.5))
        XCTAssertEqual(Progression.targets(history: past, config: linear()), [set(40, 5, .warmup), set(102.5, 5), set(102.5, 5), set(102.5, 5)])
    }

    func testLinearRepeatsTheTargetAfterAMiss() {
        let past = history([set(100, 5), set(100, 4), set(100, 3)])
        XCTAssertEqual(Progression.plan(history: past, config: linear()), .hold)
        XCTAssertEqual(Progression.targets(history: past, config: linear()), [set(100, 5), set(100, 5), set(100, 5)])
    }

    func testLinearBacksOffTenPercentAfterThreeMissesAtTheSameWeight() {
        let past = history([set(100, 5), set(100, 5), set(100, 4)], [set(100, 5), set(100, 4), set(100, 4)], [set(100, 4), set(100, 4), set(100, 3)])
        XCTAssertEqual(Progression.plan(history: past, config: linear()), .deload(toKg: 90, stalls: 3))
        XCTAssertEqual(Progression.targets(history: past, config: linear()), [set(90, 5), set(90, 5), set(90, 5)])
    }

    func testAChangeOfWeightEndsTheStreakOfMisses() {
        let past = history([set(102.5, 4)], [set(100, 4)], [set(100, 4)])
        XCTAssertEqual(Progression.plan(history: past, config: linear()), .hold)
    }

    func testAHitEndsTheStreakOfMisses() {
        let past = history([set(100, 4)], [set(100, 5)], [set(100, 4)], [set(100, 4)])
        XCTAssertEqual(Progression.plan(history: past, config: linear()), .hold)
    }

    func testADeloadLandsOnALoadableWeight() {
        // 82.5 × 0.9 = 74.25, which no bar loads to: the nearest 2.5 kg step is 75.
        let past = history([set(82.5, 4)], [set(82.5, 4)], [set(82.5, 4)])
        XCTAssertEqual(Progression.plan(history: past, config: linear()), .deload(toKg: 75, stalls: 3))
    }

    func testLinearAtBodyweightAddsARep() {
        let past = history([set(0, 12), set(0, 12)])
        XCTAssertEqual(Progression.plan(history: past, config: linear(12)), .addReps)
        XCTAssertEqual(Progression.targets(history: past, config: linear(12)), [set(0, 13), set(0, 13)])
    }

    // MARK: Greyskull LP

    private let greyskull = Progression.Config(rule: .greyskull, range: 5...5, incrementKg: 2.5)

    func testGreyskullAddsAStepWhenTheLastSetReachesItsReps() {
        let past = history([set(60, 5), set(60, 5), set(60, 7)])
        XCTAssertEqual(Progression.plan(history: past, config: greyskull), .addLoad(kg: 2.5))
        XCTAssertEqual(Progression.targets(history: past, config: greyskull), [set(62.5, 5), set(62.5, 5), set(62.5, 5)])
    }

    func testGreyskullDoublesTheStepWhenTheLastSetDoublesItsReps() {
        let past = history([set(60, 5), set(60, 5), set(60, 10)])
        XCTAssertEqual(Progression.plan(history: past, config: greyskull), .addLoad(kg: 5))
    }

    func testGreyskullBacksOffAfterOneFailedLastSet() {
        // 60 × 0.9 = 54 → nearest 2.5 kg step is 55.
        let past = history([set(60, 5), set(60, 5), set(60, 4)])
        XCTAssertEqual(Progression.plan(history: past, config: greyskull), .deload(toKg: 55, stalls: 1))
        XCTAssertEqual(Progression.targets(history: past, config: greyskull), [set(55, 5), set(55, 5), set(55, 5)])
    }

    // MARK: Double progression

    func testDoubleProgressionBacksOffAfterThreeSessionsWithoutAnExtraRep() {
        let config = Progression.Config(rule: .double, range: 8...12, incrementKg: 2.5)
        let same = [set(80, 10), set(80, 9), set(80, 8)]
        let past = history(same, same, same, [set(80, 10), set(80, 8), set(80, 8)])
        // 80 × 0.9 = 72 → 72.5.
        XCTAssertEqual(Progression.plan(history: past, config: config), .deload(toKg: 72.5, stalls: 3))
        XCTAssertEqual(Progression.targets(history: past, config: config), [set(72.5, 8), set(72.5, 8), set(72.5, 8)])
    }

    func testDoubleProgressionKeepsClimbingWhileRepsAreAdded() {
        let config = Progression.Config(rule: .double, range: 8...12, incrementKg: 2.5)
        let past = history([set(80, 8), set(80, 8)], [set(80, 9), set(80, 8)], [set(80, 9), set(80, 9)], [set(80, 10), set(80, 9)])
        XCTAssertEqual(Progression.plan(history: past, config: config), .addReps)
    }

    // MARK: Assisted machines

    func testAssistedMachineTakesHelpAwayAfterACleanSession() {
        let past = history([set(30, 8), set(30, 8)])
        XCTAssertEqual(Progression.targets(history: past, config: linear(8, assisted: true)), [set(27.5, 8), set(27.5, 8)])
    }

    func testAssistedMachineNeverGoesBelowNoHelp() {
        let past = history([set(2, 8)])
        XCTAssertEqual(Progression.targets(history: past, config: linear(8, assisted: true)), [set(0, 8)])
    }

    func testAssistedMachineGivesAStepOfHelpBackAfterThreeMisses() {
        let past = history([set(30, 6)], [set(30, 6)], [set(30, 6)])
        XCTAssertEqual(Progression.plan(history: past, config: linear(8, assisted: true)), .deload(toKg: 32.5, stalls: 3))
    }

    // MARK: Holds

    func testHoldsGainFiveSecondsASession() {
        let hold = SetValue(weightKg: 0, reps: 3, durationSeconds: 30)
        let config = Progression.Config(rule: .time, range: 1...1, incrementKg: 2.5)
        XCTAssertEqual(Progression.plan(history: history([hold, hold]), config: config), .addTime(seconds: 5))
        XCTAssertEqual(
            Progression.targets(history: history([hold, hold]), config: config),
            [SetValue(weightKg: 0, reps: 3, durationSeconds: 35), SetValue(weightKg: 0, reps: 3, durationSeconds: 35)]
        )
    }

    // MARK: Reasons

    func testEveryPlanSaysWhy() {
        XCTAssertEqual(Progression.why(.addLoad(kg: 2.5), config: linear(), unit: .kg), "Every set hit 5 reps last time: +2.5 kg.")
        XCTAssertEqual(Progression.why(.hold, config: linear(), unit: .kg), "Came up short last time: same weight, 5 reps a set.")
        XCTAssertEqual(
            Progression.why(.deload(toKg: 90, stalls: 3), config: linear(), unit: .kg),
            "Came up short 3 sessions in a row: back off to 90 kg and build up again."
        )
        XCTAssertEqual(Progression.why(.addLoad(kg: 2.5), config: linear(8, assisted: true), unit: .kg), "Every set hit 8 reps last time: 2.5 kg less help.")
        XCTAssertEqual(Progression.why(.addTime(seconds: 5), config: Progression.Config(rule: .time, range: 1...1, incrementKg: 2.5), unit: .kg), "Held every set last time: +5 s.")
        XCTAssertEqual(Progression.why(nil, config: linear(), unit: .kg), "No working sets logged yet — this session sets the baseline.")
    }

    // MARK: The exercise's own settings

    func testAnExerciseWithOnlyARepRangeStillRunsDoubleProgression() {
        let exercise = Exercise(name: "Squat (Barbell)", muscleGroup: "Quadriceps")
        XCTAssertNil(exercise.progression(unit: .kg))
        exercise.repRange = 8...12
        XCTAssertEqual(exercise.progression(unit: .kg), Progression.Config(rule: .double, range: 8...12, incrementKg: 2.5))
    }

    func testAnExerciseRemembersItsRuleAndStep() {
        let exercise = Exercise(name: "Pull Up (Assisted)", muscleGroup: "Lats")
        exercise.setProgression(.linear, range: 8...8)
        exercise.progressionStepKg = 5
        XCTAssertEqual(exercise.progression(unit: .kg), Progression.Config(rule: .linear, range: 8...8, incrementKg: 5, assisted: true))
        exercise.setProgression(nil, range: nil)
        XCTAssertNil(exercise.progression(unit: .kg))
        XCTAssertEqual(exercise.progressionRuleRaw, "")
    }
}
