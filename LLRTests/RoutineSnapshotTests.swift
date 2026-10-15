import SwiftData
import XCTest
@testable import LLR

@MainActor
final class RoutineSnapshotTests: XCTestCase {
    private var context: ModelContext!
    private var bench: Exercise!
    private var plank: Exercise!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        bench = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")
        plank = Exercise(name: "Plank", muscleGroup: "Abdominals")
        context.insert(bench)
        context.insert(plank)
    }

    /// Two exercises: a superset-tagged bench with a warm-up and a blank plan, and a timed plank.
    private func makeRoutine() -> Routine {
        let routine = Routine(name: "Push A")
        routine.categoryRaw = SessionCategory.push.rawValue
        routine.createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        context.insert(routine)

        let first = RoutineExercise(order: 0)
        context.insert(first)
        first.exercise = bench
        first.notes = "Pause on chest"
        first.restSeconds = 150
        first.supersetGroup = 1
        routine.exercises.append(first)
        let warmUp = RoutineSetPlan(order: 0, weightKg: 40, reps: 10)
        warmUp.kindRaw = "warmup"
        let blank = RoutineSetPlan(order: 1)
        for plan in [warmUp, blank] {
            context.insert(plan)
            first.sets.append(plan)
        }

        let second = RoutineExercise(order: 1)
        context.insert(second)
        second.exercise = plank
        routine.exercises.append(second)
        let hold = RoutineSetPlan(order: 0, weightKg: nil, reps: 1)
        hold.durationSeconds = 45
        context.insert(hold)
        second.sets.append(hold)
        return routine
    }

    func testRestoreEqualsOriginalIncludingNestedPlans() throws {
        let original = makeRoutine()
        let before = RoutineSnapshot(original)
        context.delete(original)
        try context.save()

        let restored = before.restore(in: context)
        try context.save()

        XCTAssertEqual(RoutineSnapshot(restored), before)
        XCTAssertEqual(restored.name, "Push A")
        XCTAssertEqual(restored.category, .push)
        XCTAssertEqual(restored.orderedExercises.count, 2)
        let plans = restored.orderedExercises[0].orderedSets
        XCTAssertEqual(plans.map(\.kindRaw), ["warmup", "normal"])
        XCTAssertNil(plans[1].weightKg)
        XCTAssertEqual(restored.orderedExercises[1].orderedSets[0].durationSeconds, 45)
    }

    func testRevertUndoesEditsInPlace() throws {
        let routine = makeRoutine()
        let before = RoutineSnapshot(routine)
        // What a cancelled builder session leaves behind: a cleared name, a removed exercise, a new set.
        routine.name = ""
        context.delete(routine.orderedExercises[1])
        routine.orderedExercises[0].sets.append(RoutineSetPlan(order: 9, reps: 3))
        try context.save()

        before.revert(routine, in: context)
        try context.save()

        XCTAssertEqual(RoutineSnapshot(routine), before)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Routine>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<RoutineExercise>()), 2, "no orphaned copies left behind")
    }

    func testRestoreKeepsRestNotesSupersetAndCreationDate() throws {
        let original = makeRoutine()
        let originalID = original.id
        let snapshot = RoutineSnapshot(original)
        context.delete(original)
        let restored = snapshot.restore(in: context)

        let entry = restored.orderedExercises[0]
        XCTAssertEqual(entry.restSeconds, 150)
        XCTAssertEqual(entry.notes, "Pause on chest")
        XCTAssertEqual(entry.supersetGroup, 1)
        XCTAssertNil(restored.orderedExercises[1].restSeconds)
        XCTAssertEqual(restored.createdAt, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(restored.id, originalID)
    }

    func testDeleteCascadesToExercisesAndPlans() throws {
        let routine = makeRoutine()
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<RoutineExercise>()), 2)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<RoutineSetPlan>()), 3)

        context.delete(routine)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Routine>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<RoutineExercise>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<RoutineSetPlan>()), 0)
    }

    func testDeleteAndRestoreLeaveFinishedWorkoutsAndExercisesAlone() throws {
        let workout = Workout(startedAt: Date(timeIntervalSince1970: 1_700_100_000))
        workout.endedAt = workout.startedAt.addingTimeInterval(3600)
        workout.name = "Push"
        context.insert(workout)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        workout.exercises.append(entry)
        let set = SetEntry(order: 0, weightKg: 60, reps: 8)
        context.insert(set)
        entry.sets.append(set)

        let routine = makeRoutine()
        let snapshot = RoutineSnapshot(routine)
        context.delete(routine)
        snapshot.restore(in: context)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Workout>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutExercise>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetEntry>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 2)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Routine>()), 1)
        XCTAssertEqual(workout.orderedExercises.first?.exercise?.name, "Bench Press (Barbell)")
    }
}
