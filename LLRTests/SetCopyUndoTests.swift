import SwiftData
import XCTest
@testable import LLR

@MainActor
final class SetCopyUndoTests: XCTestCase {
    private var context: ModelContext!
    private var workout: Workout!
    private var entry: WorkoutExercise!
    private var model: ActiveWorkoutModel!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        let bench = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")
        context.insert(bench)
        workout = Workout()
        context.insert(workout)
        entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        workout.exercises.append(entry)
        // 40 × 10 warm-up (done), 80 × 8 (done, rated), 80 × 7 (not done).
        for (index, spec) in [(40.0, 10, SetKind.warmup, true), (80, 8, .normal, true), (80, 7, .normal, false)].enumerated() {
            let set = SetEntry(order: index, weightKg: spec.0, reps: spec.1)
            set.kind = spec.2
            if spec.3 { set.completedAt = Date(timeIntervalSince1970: 1_000 + Double(index)) }
            context.insert(set)
            entry.sets.append(set)
        }
        entry.orderedSets[1].rir = 2
        model = ActiveWorkoutModel(workout: workout, isHistory: true)
    }

    private var shape: [String] {
        entry.orderedSets.map { "\(WeightUnit.kg.format(kg: $0.weightKg))x\($0.reps)\($0.kind == .warmup ? "w" : "")\($0.completedAt == nil ? "" : "✓")" }
    }

    func testDuplicatingASetPutsAnUntickedCopyRightAfterIt() {
        model.duplicate(entry.orderedSets[1])
        XCTAssertEqual(shape, ["40x10w✓", "80x8✓", "80x8", "80x7"])
        XCTAssertNil(entry.orderedSets[2].rir, "the copy hasn't been done, so it has no effort yet")
        XCTAssertEqual(entry.orderedSets.map(\.order), [0, 1, 2, 3])
    }

    func testDuplicatingKeepsTheSetKindAndHoldTime() {
        entry.orderedSets[0].durationSeconds = 30
        model.duplicate(entry.orderedSets[0])
        XCTAssertEqual(entry.orderedSets[1].kind, .warmup)
        XCTAssertEqual(entry.orderedSets[1].durationSeconds, 30)
    }

    func testADeletedSetCanBeTakenBackExactlyAsItWas() {
        model.delete(entry.orderedSets[1])
        XCTAssertEqual(shape, ["40x10w✓", "80x7"])
        XCTAssertEqual(model.removal?.title, "Set deleted")
        model.undoRemoval()
        XCTAssertEqual(shape, ["40x10w✓", "80x8✓", "80x7"])
        XCTAssertEqual(entry.orderedSets[1].rir, 2)
        XCTAssertEqual(entry.orderedSets[1].completedAt, Date(timeIntervalSince1970: 1_001))
        XCTAssertNil(model.removal, "taking it back uses the undo up")
    }

    func testOnlyTheLastDeletionCanBeTakenBack() {
        model.delete(entry.orderedSets[0])
        model.delete(entry.orderedSets[0])
        model.undoRemoval()
        XCTAssertEqual(shape, ["80x8✓", "80x7"])
        model.undoRemoval()
        XCTAssertEqual(shape, ["80x8✓", "80x7"])
    }

    func testUndoDoesNothingOnceTheExerciseItselfIsGone() {
        model.delete(entry.orderedSets[0])
        context.delete(entry)
        model.undoRemoval()
        XCTAssertNil(model.removal)
    }
}
