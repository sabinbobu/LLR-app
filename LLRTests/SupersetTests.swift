import SwiftData
import XCTest
@testable import LLR

final class SupersetTests: XCTestCase {
    private func member(_ group: Int?, _ done: [Bool]) -> Superset.Member { Superset.Member(group: group, completed: done) }

    func testPairingWithTheNextExerciseStartsAGroup() {
        XCTAssertEqual(Superset.pairing([nil, nil, nil], at: 0), [1, 1, nil])
    }

    func testPairingJoinsAGroupThatAlreadyExists() {
        XCTAssertEqual(Superset.pairing([4, 4, nil], at: 1), [4, 4, 4])
        XCTAssertEqual(Superset.pairing([nil, 4, 4], at: 0), [4, 4, 4])
    }

    func testPairingAcrossTwoGroupsMergesThem() {
        XCTAssertEqual(Superset.pairing([1, 1, 2, 2], at: 1), [1, 1, 1, 1])
    }

    func testANewGroupNeverReusesANumberInUse() {
        XCTAssertEqual(Superset.pairing([7, 7, nil, nil], at: 2), [7, 7, 8, 8])
    }

    func testTheLastExerciseHasNothingToPairWith() {
        XCTAssertEqual(Superset.pairing([nil, nil], at: 1), [nil, nil])
    }

    func testUnpairingOneOfThreeLeavesTheOtherTwoTogether() {
        XCTAssertEqual(Superset.unpairing([1, 1, 1], at: 1), [1, nil, 1])
    }

    func testUnpairingOneOfTwoDissolvesTheGroup() {
        XCTAssertEqual(Superset.unpairing([nil, 3, 3], at: 2), [nil, nil, nil])
    }

    func testARoundEndsOnceEveryMemberHasDoneThatSet() {
        let afterFirst = [member(1, [true, false, false]), member(1, [false, false, false])]
        XCTAssertFalse(Superset.endsRound(afterFirst, exercise: 0, set: 0))
        let afterBoth = [member(1, [true, false, false]), member(1, [true, false, false])]
        XCTAssertTrue(Superset.endsRound(afterBoth, exercise: 1, set: 0))
    }

    func testARoundEndsEarlyWhenTheOtherExerciseHasFewerSets() {
        let uneven = [member(1, [true, true, true]), member(1, [true, true])]
        XCTAssertTrue(Superset.endsRound(uneven, exercise: 0, set: 2))
    }

    func testOutsideASupersetEverySetEndsItsRound() {
        let plain = [member(nil, [true, false]), member(nil, [false])]
        XCTAssertTrue(Superset.endsRound(plain, exercise: 0, set: 0))
    }

    func testNextSetAlternatesThroughASupersetThenMovesOn() {
        var members = [member(1, [false, false]), member(1, [false, false]), member(nil, [false])]
        var order: [Superset.Position] = []
        while let next = Superset.next(in: members) {
            order.append(next)
            members[next.exercise].completed[next.set] = true
        }
        XCTAssertEqual(order, [
            Superset.Position(exercise: 0, set: 0), Superset.Position(exercise: 1, set: 0),
            Superset.Position(exercise: 0, set: 1), Superset.Position(exercise: 1, set: 1),
            Superset.Position(exercise: 2, set: 0),
        ])
    }

    func testNextSetFinishesAnEarlierExerciseBeforeTheSuperset() {
        let members = [member(nil, [true, false]), member(1, [false]), member(1, [false])]
        XCTAssertEqual(Superset.next(in: members), Superset.Position(exercise: 0, set: 1))
    }

    func testTagsLetterTheGroupsInOrderAndSkipALoneMember() {
        let tags = Superset.tags([nil, 5, 5, 9, 2, 2, 2])
        XCTAssertEqual(tags, [
            nil,
            Superset.Tag(letter: "A", position: 1, count: 2), Superset.Tag(letter: "A", position: 2, count: 2),
            nil,
            Superset.Tag(letter: "B", position: 1, count: 3), Superset.Tag(letter: "B", position: 2, count: 3),
            Superset.Tag(letter: "B", position: 3, count: 3),
        ])
    }
}

@MainActor
final class SupersetWorkoutTests: XCTestCase {
    private var context: ModelContext!
    private var exercises: [Exercise] = []

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        exercises = ["Bench Press (Barbell)", "Bent Over Row (Barbell)", "Bicep Curl (Dumbbell)"].map {
            let exercise = Exercise(name: $0, muscleGroup: "Chest")
            // A known rest, so "no timer" can only mean the superset held it back.
            exercise.restSeconds = 90
            context.insert(exercise)
            return exercise
        }
        RestTimer.shared.skip()
    }

    override func tearDown() async throws {
        RestTimer.shared.skip()
    }

    /// Three exercises, two sets of 50 × 10 each, nothing ticked.
    private func liveWorkout() -> Workout {
        let workout = Workout()
        context.insert(workout)
        for (order, exercise) in exercises.enumerated() {
            let entry = WorkoutExercise(order: order)
            context.insert(entry)
            entry.exercise = exercise
            workout.exercises.append(entry)
            for index in 0..<2 {
                let set = SetEntry(order: index, weightKg: 50, reps: 10)
                context.insert(set)
                entry.sets.append(set)
            }
        }
        return workout
    }

    func testPairingAndUnpairingFromTheWorkout() {
        let workout = liveWorkout()
        let model = ActiveWorkoutModel(workout: workout)
        let entries = workout.orderedExercises
        model.pairWithNext(entries[0])
        XCTAssertEqual(entries.map(\.supersetGroup), [1, 1, nil])
        XCTAssertEqual(model.supersetTag(for: entries[1]), Superset.Tag(letter: "A", position: 2, count: 2))
        model.unpair(entries[0])
        XCTAssertEqual(entries.map(\.supersetGroup), [nil, nil, nil])
        XCTAssertNil(model.supersetTag(for: entries[1]))
    }

    func testRestWaitsForTheEndOfTheRound() {
        let workout = liveWorkout()
        let model = ActiveWorkoutModel(workout: workout)
        let entries = workout.orderedExercises
        model.pairWithNext(entries[0])
        model.toggle(entries[0].orderedSets[0])
        XCTAssertFalse(RestTimer.shared.isRunning, "straight on to the paired exercise")
        model.toggle(entries[1].orderedSets[0])
        XCTAssertTrue(RestTimer.shared.isRunning, "the round is done")
    }

    func testRepeatingAWorkoutKeepsItsSupersets() {
        let workout = liveWorkout()
        let model = ActiveWorkoutModel(workout: workout)
        model.pairWithNext(workout.orderedExercises[1])
        workout.orderedExercises.flatMap(\.orderedSets).forEach { $0.completedAt = .now }
        workout.endedAt = .now
        let copy = WorkoutFactory.start(copying: workout, in: context)
        XCTAssertEqual(copy.orderedExercises.map(\.supersetGroup), [nil, 1, 1])
    }

    func testASupersetSurvivesBeingSavedAsARoutineAndStartedAgain() {
        let workout = liveWorkout()
        ActiveWorkoutModel(workout: workout).pairWithNext(workout.orderedExercises[0])
        workout.orderedExercises.flatMap(\.orderedSets).forEach { $0.completedAt = .now }
        workout.endedAt = .now
        let routine = RoutineFactory.save(workout, in: context)
        XCTAssertEqual(routine.orderedExercises.map(\.supersetGroup), [1, 1, nil])
        let started = WorkoutFactory.start(routine: routine, in: context)
        XCTAssertEqual(started.orderedExercises.map(\.supersetGroup), [1, 1, nil])
    }

    func testCancellingAnEditPutsSupersetsBack() {
        let workout = liveWorkout()
        let model = ActiveWorkoutModel(workout: workout)
        model.pairWithNext(workout.orderedExercises[0])
        let snapshot = WorkoutSnapshot(workout)
        model.unpair(workout.orderedExercises[0])
        snapshot.restore(into: workout, in: context)
        XCTAssertEqual(workout.orderedExercises.map(\.supersetGroup), [1, 1, nil])
    }
}
