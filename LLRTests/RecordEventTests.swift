import SwiftData
import XCTest
@testable import LLR

@MainActor
final class RecordEventTests: XCTestCase {
    private var context: ModelContext!
    private var bench: Exercise!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        bench = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")
        context.insert(bench)
        RestTimer.shared.skip()
    }

    /// A finished session in `section`, one working set of `weightKg` × `reps`, a week ago.
    private func pastSession(weightKg: Double, reps: Int, section: WorkoutSection = .gym) {
        let workout = Workout(startedAt: .now.addingTimeInterval(-7 * 86_400))
        workout.endedAt = workout.startedAt.addingTimeInterval(3600)
        workout.section = section
        context.insert(workout)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        workout.exercises.append(entry)
        let set = SetEntry(order: 0, weightKg: weightKg, reps: reps)
        set.completedAt = workout.startedAt
        context.insert(set)
        entry.sets.append(set)
    }

    private func liveEntry(in workout: Workout) -> WorkoutExercise {
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        workout.exercises.append(entry)
        return entry
    }

    @discardableResult
    private func addSet(_ weightKg: Double, _ reps: Int, kind: SetKind = .normal, to entry: WorkoutExercise) -> SetEntry {
        let set = SetEntry(order: entry.sets.count, weightKg: weightKg, reps: reps)
        set.kind = kind
        context.insert(set)
        entry.sets.append(set)
        return set
    }

    func testTogglingASetThatBeatsHistoryEmitsARecordEvent() throws {
        pastSession(weightKg: 80, reps: 8)
        let workout = Workout()
        context.insert(workout)
        let set = addSet(85, 8, to: liveEntry(in: workout))

        let model = ActiveWorkoutModel(workout: workout)
        XCTAssertTrue(model.toggle(set))

        let event = try XCTUnwrap(model.recordEvent)
        XCTAssertEqual(event.exerciseName, "Bench Press (Barbell)")
        XCTAssertTrue(event.kinds.contains(.weight))
    }

    func testAWarmUpSetNeverEmitsARecordEvent() throws {
        pastSession(weightKg: 80, reps: 8)
        let workout = Workout()
        context.insert(workout)
        let set = addSet(85, 8, kind: .warmup, to: liveEntry(in: workout))

        let model = ActiveWorkoutModel(workout: workout)
        XCTAssertTrue(model.toggle(set))
        XCTAssertNil(model.recordEvent)
    }

    func testAFirstSessionNeverEmitsARecordEvent() throws {
        let workout = Workout()
        context.insert(workout)
        let set = addSet(85, 8, to: liveEntry(in: workout))

        let model = ActiveWorkoutModel(workout: workout)
        XCTAssertTrue(model.toggle(set))
        XCTAssertNil(model.recordEvent, "no history means no baseline to beat")
    }

    func testKinetoWorkoutsNeverEmitARecordEvent() throws {
        pastSession(weightKg: 80, reps: 8, section: .kineto)
        let workout = Workout()
        workout.section = .kineto
        context.insert(workout)
        let set = addSet(85, 8, to: liveEntry(in: workout))

        let model = ActiveWorkoutModel(workout: workout)
        XCTAssertTrue(model.toggle(set))
        XCTAssertNil(model.recordEvent, "PR hype has no place in back-care")
    }

    func testUncompletingASetNeverEmitsARecordEvent() throws {
        pastSession(weightKg: 80, reps: 8)
        let workout = Workout()
        context.insert(workout)
        let set = addSet(85, 8, to: liveEntry(in: workout))
        set.completedAt = .now

        let model = ActiveWorkoutModel(workout: workout)
        XCTAssertTrue(model.toggle(set))
        XCTAssertNil(model.recordEvent)
    }
}
