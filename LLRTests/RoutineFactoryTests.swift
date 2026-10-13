import SwiftData
import XCTest
@testable import LLR

@MainActor
final class RoutineFactoryTests: XCTestCase {
    private var context: ModelContext!
    private var bench: Exercise!
    private var plank: Exercise!
    private var curl: Exercise!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        bench = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")
        bench.restSeconds = 180
        plank = Exercise(name: "Plank", muscleGroup: "Abdominals")
        curl = Exercise(name: "Bicep Curl (Dumbbell)", muscleGroup: "Biceps")
        [bench, plank, curl].forEach { context.insert($0!) }
    }

    private struct SetSpec {
        var weightKg: Double = 0
        var reps: Int
        var kind: SetKind = .normal
        var seconds: Int? = nil
        var done = true
    }

    /// Bench: warm-up, one working set, one left unticked. Curl: nothing ticked. Plank: one hold.
    private func finishedWorkout() -> Workout {
        let workout = Workout(startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        workout.endedAt = workout.startedAt.addingTimeInterval(3600)
        workout.name = "Push"
        context.insert(workout)
        let plan: [(Exercise, [SetSpec])] = [
            (bench, [SetSpec(weightKg: 40, reps: 10, kind: .warmup), SetSpec(weightKg: 80, reps: 8), SetSpec(weightKg: 80, reps: 7, done: false)]),
            (curl, [SetSpec(weightKg: 12, reps: 12, done: false)]),
            (plank, [SetSpec(reps: 1, seconds: 60)]),
        ]
        for (order, (exercise, sets)) in plan.enumerated() {
            let entry = WorkoutExercise(order: order)
            context.insert(entry)
            entry.exercise = exercise
            workout.exercises.append(entry)
            for (index, spec) in sets.enumerated() {
                let set = SetEntry(order: index, weightKg: spec.weightKg, reps: spec.reps)
                set.kind = spec.kind
                set.durationSeconds = spec.seconds
                set.completedAt = spec.done ? workout.startedAt : nil
                context.insert(set)
                entry.sets.append(set)
            }
        }
        return workout
    }

    func testRoutineKeepsWhatWasDoneInOrderAndLeavesWeightBlank() throws {
        let routine = RoutineFactory.save(finishedWorkout(), in: context)

        XCTAssertEqual(routine.name, "Push")
        XCTAssertEqual(routine.section, .gym)
        let entries = routine.orderedExercises
        XCTAssertEqual(entries.map { $0.exercise?.name }, ["Bench Press (Barbell)", "Plank"], "the curl had nothing ticked")
        XCTAssertEqual(entries.map(\.order), [0, 1])
        XCTAssertEqual(entries[0].restSeconds, 180)
        let benchPlans = entries[0].orderedSets
        XCTAssertEqual(benchPlans.map(\.reps), [10, 8], "the unticked set is not part of the routine")
        XCTAssertEqual(benchPlans.map(\.kind), [.warmup, .normal])
        XCTAssertEqual(benchPlans.map(\.weightKg), [nil, nil])
        XCTAssertEqual(entries[1].orderedSets.map(\.durationSeconds), [60])
        XCTAssertTrue(entries[1].isDurationBased)
    }

    func testUnnamedWorkoutLendsItsTimeOfDayTitleSoTheRoutineIsNeverNameless() {
        let workout = finishedWorkout()
        workout.name = ""
        let routine = RoutineFactory.save(workout, in: context)
        XCTAssertEqual(routine.name, workout.title)
        XCTAssertFalse(routine.name.isEmpty, "the builder discards a nameless routine on Cancel")
    }

    func testStartingTheSavedRoutineUsesItsRepsAndTheLatestWeights() throws {
        let routine = RoutineFactory.save(finishedWorkout(), in: context)

        let started = WorkoutFactory.start(routine: routine, in: context)
        XCTAssertEqual(started.title, "Push")
        let benchSets = try XCTUnwrap(started.orderedExercises.first).orderedSets
        XCTAssertEqual(benchSets.map(\.reps), [10, 8])
        XCTAssertEqual(benchSets.map(\.weightKg), [40, 80])
        XCTAssertEqual(benchSets.map(\.kind), [.warmup, .normal])
        XCTAssertTrue(benchSets.allSatisfy { $0.completedAt == nil })
    }

    func testStartingAnEditedRoutineReflectsTheEditsAndLeavesHistoryAlone() throws {
        let source = finishedWorkout()
        let routine = RoutineFactory.save(source, in: context)
        let createdAt = routine.createdAt

        routine.name = "Push (edited)"
        let removed = try XCTUnwrap(routine.orderedExercises.last)
        routine.exercises.removeAll { $0 === removed }
        context.delete(removed)

        let started = WorkoutFactory.start(routine: routine, in: context)
        XCTAssertEqual(started.title, "Push (edited)")
        XCTAssertEqual(started.orderedExercises.compactMap { $0.exercise?.name }, ["Bench Press (Barbell)"])
        XCTAssertEqual(routine.createdAt, createdAt)
        XCTAssertEqual(source.orderedExercises.count, 3, "finished workouts are never touched by routine edits")
    }
}
