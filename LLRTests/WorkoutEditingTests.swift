import SwiftData
import XCTest
@testable import LLR

@MainActor
final class WorkoutEditingTests: XCTestCase {
    private var context: ModelContext!
    private var bench: Exercise!
    private var row: Exercise!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        bench = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")
        row = Exercise(name: "Bent Over Row (Barbell)", muscleGroup: "Upper Back")
        context.insert(bench)
        context.insert(row)
        RestTimer.shared.skip()
    }

    /// A finished workout: bench 2 × (80 × 8), row 1 × (60 × 10).
    private func finishedWorkout() -> Workout {
        let workout = Workout(startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        workout.endedAt = workout.startedAt.addingTimeInterval(3600)
        workout.name = "Push"
        context.insert(workout)
        for (order, (exercise, sets)) in [(bench!, [(80.0, 8), (80.0, 8)]), (row!, [(60.0, 10)])].enumerated() {
            let entry = WorkoutExercise(order: order)
            context.insert(entry)
            entry.exercise = exercise
            workout.exercises.append(entry)
            for (index, value) in sets.enumerated() {
                let set = SetEntry(order: index, weightKg: value.0, reps: value.1)
                set.completedAt = workout.startedAt
                context.insert(set)
                entry.sets.append(set)
            }
        }
        return workout
    }

    func testHistoryTickCompletesAtWorkoutTimeWithoutRest() throws {
        let workout = finishedWorkout()
        let model = ActiveWorkoutModel(workout: workout, isHistory: true)
        let entry = try XCTUnwrap(workout.orderedExercises.first)
        model.addSet(to: entry)
        let added = try XCTUnwrap(entry.orderedSets.last)
        XCTAssertNil(added.completedAt)
        XCTAssertTrue(model.toggle(added))
        XCTAssertEqual(added.completedAt, workout.startedAt)
        XCTAssertFalse(RestTimer.shared.isRunning, "editing history must never start a rest")
    }

    func testSaveKeepsWorkoutFinishedAndDropsDrafts() throws {
        let workout = finishedWorkout()
        let model = ActiveWorkoutModel(workout: workout, isHistory: true)
        let entry = try XCTUnwrap(workout.orderedExercises.first)
        model.addSet(to: entry)
        model.add(Exercise(name: "Dip", muscleGroup: "Chest"))
        model.saveEdits()
        XCTAssertNotNil(workout.endedAt)
        XCTAssertEqual(workout.orderedExercises.count, 2, "the untouched new exercise had no ticked sets")
        XCTAssertEqual(workout.completedSets.count, 3)
    }

    func testCancelRestoresEverythingExactly() throws {
        let workout = finishedWorkout()
        let original = WorkoutSnapshot(workout)
        let model = ActiveWorkoutModel(workout: workout, isHistory: true)

        workout.name = "Typo day"
        workout.startedAt = workout.startedAt.addingTimeInterval(-86_400)
        let benchEntry = try XCTUnwrap(workout.orderedExercises.first)
        benchEntry.orderedSets.first?.weightKg = 800
        benchEntry.orderedSets.last?.completedAt = nil
        model.remove(try XCTUnwrap(workout.orderedExercises.last))
        model.addSet(to: benchEntry)

        original.restore(into: workout, in: context)
        XCTAssertEqual(WorkoutSnapshot(workout), original)
        XCTAssertEqual(workout.name, "Push")
        XCTAssertEqual(workout.volumeKg, 80 * 8 * 2 + 60 * 10)
    }

    func testCancelRestoresAnEffortRating() throws {
        let workout = finishedWorkout()
        let set = try XCTUnwrap(workout.orderedExercises.first?.orderedSets.first)
        set.rir = 2
        let original = WorkoutSnapshot(workout)

        set.rir = 0
        XCTAssertNotEqual(WorkoutSnapshot(workout), original, "a changed rating is an edit Cancel must undo")
        original.restore(into: workout, in: context)
        XCTAssertEqual(workout.orderedExercises.first?.orderedSets.first?.rir, 2)
    }

    func testLaunchCleanupRemovesOnlyEmptyFinishedWorkouts() throws {
        let kept = finishedWorkout()
        let interrupted = Workout(startedAt: .now.addingTimeInterval(-3600))
        interrupted.endedAt = .now
        context.insert(interrupted)
        let live = Workout()
        context.insert(live)
        try context.save()

        WorkoutFactory.removeEmptyHistory(in: context)

        let remaining = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(Set(remaining.map(\.id)), [kept.id, live.id], "an unfinished workout is in progress, not history")
    }

    func testCancelWithoutChangesLeavesSetsUntouched() throws {
        let workout = finishedWorkout()
        let ids = workout.orderedExercises.flatMap(\.orderedSets).map(\.persistentModelID)
        WorkoutSnapshot(workout).restore(into: workout, in: context)
        XCTAssertEqual(workout.orderedExercises.flatMap(\.orderedSets).map(\.persistentModelID), ids)
    }

    func testCancelRestoresDurationSets() throws {
        let workout = Workout(startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        workout.endedAt = workout.startedAt.addingTimeInterval(600)
        context.insert(workout)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        workout.exercises.append(entry)
        let set = SetEntry(order: 0, weightKg: 0, reps: 5)
        set.durationSeconds = 15
        set.completedAt = workout.startedAt
        context.insert(set)
        entry.sets.append(set)

        let original = WorkoutSnapshot(workout)
        set.durationSeconds = 99

        original.restore(into: workout, in: context)
        XCTAssertEqual(workout.orderedExercises.first?.orderedSets.first?.durationSeconds, 15)
    }

    func testNewWorkoutDefaultsToGymSection() throws {
        let workout = Workout()
        XCTAssertEqual(workout.section, .gym, "existing rows with no stored value must still read as gym")
    }

    func testRemoveEmptyHistoryKeepsAKinetoSessionWithPainButExpelsAnEmptyGymOne() throws {
        let kineto = Workout(startedAt: .now.addingTimeInterval(-600))
        kineto.endedAt = .now
        kineto.section = .kineto
        kineto.backPainBefore = 6
        context.insert(kineto)

        let emptyGym = Workout(startedAt: .now.addingTimeInterval(-600))
        emptyGym.endedAt = .now
        context.insert(emptyGym)
        try context.save()

        WorkoutFactory.removeEmptyHistory(in: context)

        let remaining = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(Set(remaining.map(\.id)), [kineto.id], "pain recorded is the point of a Kineto check-in; an empty gym log has nothing worth keeping")
    }

    func testFinishKeepsAKinetoSessionWithPainAndNoTickedSets() throws {
        let workout = Workout()
        workout.section = .kineto
        context.insert(workout)
        let model = ActiveWorkoutModel(workout: workout)
        workout.backPainBefore = 4
        workout.backPainAfter = 7

        model.finish()

        XCTAssertNotNil(workout.endedAt)
        let remaining = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(remaining.map(\.id), [workout.id])
    }

    func testSessionsAreScopedToTheirOwnSection() throws {
        let gymWorkout = Workout(startedAt: .now.addingTimeInterval(-3600))
        gymWorkout.endedAt = .now
        context.insert(gymWorkout)
        let gymEntry = WorkoutExercise(order: 0)
        context.insert(gymEntry)
        gymEntry.exercise = bench
        gymWorkout.exercises.append(gymEntry)
        let gymSet = SetEntry(order: 0, weightKg: 80, reps: 8)
        gymSet.completedAt = gymWorkout.startedAt
        context.insert(gymSet)
        gymEntry.sets.append(gymSet)

        let kinetoWorkout = Workout(startedAt: .now.addingTimeInterval(-1800))
        kinetoWorkout.endedAt = .now
        kinetoWorkout.section = .kineto
        context.insert(kinetoWorkout)
        let kinetoEntry = WorkoutExercise(order: 0)
        context.insert(kinetoEntry)
        kinetoEntry.exercise = bench
        kinetoWorkout.exercises.append(kinetoEntry)
        let kinetoSet = SetEntry(order: 0, weightKg: 0, reps: 5)
        kinetoSet.durationSeconds = 15
        kinetoSet.completedAt = kinetoWorkout.startedAt
        context.insert(kinetoSet)
        kinetoEntry.sets.append(kinetoSet)

        XCTAssertEqual(bench.sessions(section: .gym).map(\.date), [gymWorkout.startedAt])
        XCTAssertEqual(bench.sessions(section: .kineto).map(\.date), [kinetoWorkout.startedAt])
    }

    func testIsDurationBasedRequiresEverySetToAgree() throws {
        let workout = Workout()
        context.insert(workout)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        workout.exercises.append(entry)
        XCTAssertFalse(entry.isDurationBased, "no sets yet")

        let hold = SetEntry(order: 0, weightKg: 0, reps: 5)
        hold.durationSeconds = 15
        context.insert(hold)
        entry.sets.append(hold)
        XCTAssertTrue(entry.isDurationBased)

        let lift = SetEntry(order: 1, weightKg: 40, reps: 8)
        context.insert(lift)
        entry.sets.append(lift)
        XCTAssertFalse(entry.isDurationBased, "a mixed card falls back to the weight/reps header")
    }

    func testDeletingAWorkoutCascadesButKeepsTheExerciseAndItsOtherSessions() throws {
        let doomed = finishedWorkout()
        let kept = finishedWorkout()
        kept.startedAt = doomed.startedAt.addingTimeInterval(86_400)
        XCTAssertEqual(bench.sessions().count, 2)

        WorkoutActions.delete(doomed, in: context)

        let sets = try context.fetch(FetchDescriptor<SetEntry>())
        XCTAssertEqual(sets.count, 3, "only the surviving workout's sets remain")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Exercise>()).count, 2)
        XCTAssertEqual(bench.sessions().count, 1, "history and prefill no longer see the deleted session")
    }

    func testRepeatCopiesCompletedSetsAndLeavesTheSourceUntouched() throws {
        let source = finishedWorkout()
        let started = WorkoutFactory.start(copying: source, in: context)

        XCTAssertNil(started.endedAt)
        XCTAssertEqual(started.orderedExercises.compactMap { $0.exercise?.name }, ["Bench Press (Barbell)", "Bent Over Row (Barbell)"])
        XCTAssertEqual(started.orderedExercises.first?.orderedSets.map(\.reps), [8, 8])
        XCTAssertEqual(source.orderedExercises.count, 2)
        XCTAssertNotNil(source.endedAt)
        XCTAssertEqual(source.orderedExercises.first?.orderedSets.count, 2)
    }

    func testDeleteMessageMentionsPainOnlyWhenRecorded() {
        let workout = finishedWorkout()
        XCTAssertFalse(WorkoutActions.deleteMessage(for: workout).contains("pain"))
        XCTAssertTrue(WorkoutActions.repeatLabel(canStart: false).contains("finish current first"))
    }
}
