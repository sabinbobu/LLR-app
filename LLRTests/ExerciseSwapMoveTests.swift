import SwiftData
import XCTest
@testable import LLR

@MainActor
final class ExerciseSwapMoveTests: XCTestCase {
    private var context: ModelContext!
    private var workout: Workout!
    private var model: ActiveWorkoutModel!
    private var bench: Exercise!
    private var row: Exercise!
    private var curl: Exercise!
    private var press: Exercise!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        bench = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")
        row = Exercise(name: "Bent Over Row (Barbell)", muscleGroup: "Lats")
        curl = Exercise(name: "Bicep Curl (Dumbbell)", muscleGroup: "Biceps")
        press = Exercise(name: "Chest Press (Machine)", muscleGroup: "Chest")
        [bench, row, curl, press].forEach { context.insert($0!) }

        // The machine press was last done for 2 × 12 at 30 kg.
        let past = Workout(startedAt: .now.addingTimeInterval(-7 * 86_400))
        past.endedAt = past.startedAt.addingTimeInterval(3_600)
        context.insert(past)
        add(press, to: past, sets: [(30, 12, true), (30, 12, true)])

        workout = Workout()
        context.insert(workout)
        add(bench, to: workout, sets: [(80, 8, false), (80, 8, false), (80, 8, false)])
        add(row, to: workout, sets: [(60, 10, false)])
        add(curl, to: workout, sets: [(12, 12, false)])
        model = ActiveWorkoutModel(workout: workout, isHistory: true)
    }

    private func add(_ exercise: Exercise, to workout: Workout, sets: [(Double, Int, Bool)]) {
        let entry = WorkoutExercise(order: workout.exercises.count)
        context.insert(entry)
        entry.exercise = exercise
        workout.exercises.append(entry)
        for (index, spec) in sets.enumerated() {
            let set = SetEntry(order: index, weightKg: spec.0, reps: spec.1)
            if spec.2 { set.completedAt = workout.startedAt }
            context.insert(set)
            entry.sets.append(set)
        }
    }

    private var names: [String] { workout.orderedExercises.map { $0.exercise?.name ?? "?" } }
    private func shape(_ entry: WorkoutExercise) -> [String] {
        entry.orderedSets.map { "\(WeightUnit.kg.format(kg: $0.weightKg))x\($0.reps)\($0.completedAt == nil ? "" : "✓")" }
    }

    func testSwappingAnUntouchedExerciseReplacesItInPlaceWithItsOwnNumbers() {
        model.swap(workout.orderedExercises[0], to: press)
        XCTAssertEqual(names, ["Chest Press (Machine)", "Bent Over Row (Barbell)", "Bicep Curl (Dumbbell)"])
        XCTAssertEqual(shape(workout.orderedExercises[0]), ["30x12", "30x12", "30x12"])
    }

    func testSwappingAfterSomeSetsKeepsThemOnTheOldExerciseAndContinuesOnTheNew() {
        let entry = workout.orderedExercises[0]
        entry.orderedSets[0].completedAt = .now
        model.swap(entry, to: press)
        XCTAssertEqual(names, ["Bench Press (Barbell)", "Chest Press (Machine)", "Bent Over Row (Barbell)", "Bicep Curl (Dumbbell)"])
        XCTAssertEqual(shape(workout.orderedExercises[0]), ["80x8✓"])
        XCTAssertEqual(shape(workout.orderedExercises[1]), ["30x12", "30x12"])
        XCTAssertEqual(workout.orderedExercises.map(\.order), [0, 1, 2, 3])
    }

    func testSwappingKeepsTheSupersetTogether() {
        model.pairWithNext(workout.orderedExercises[0])
        model.swap(workout.orderedExercises[0], to: press)
        XCTAssertEqual(workout.orderedExercises.map(\.supersetGroup), [1, 1, nil])
    }

    func testMovingAnExerciseDownAndBackUp() {
        model.move(workout.orderedExercises[0], by: 1)
        XCTAssertEqual(names, ["Bent Over Row (Barbell)", "Bench Press (Barbell)", "Bicep Curl (Dumbbell)"])
        model.move(workout.orderedExercises[1], by: -1)
        XCTAssertEqual(names, ["Bench Press (Barbell)", "Bent Over Row (Barbell)", "Bicep Curl (Dumbbell)"])
    }

    func testTheEndsHaveNowhereToMove() {
        XCTAssertFalse(model.canMove(workout.orderedExercises[0], by: -1))
        XCTAssertFalse(model.canMove(workout.orderedExercises[2], by: 1))
        XCTAssertTrue(model.canMove(workout.orderedExercises[1], by: 1))
        model.move(workout.orderedExercises[0], by: -1)
        XCTAssertEqual(names.first, "Bench Press (Barbell)")
    }

    func testARemovedExerciseComesBackWithItsSetsPlaceAndSuperset() {
        model.pairWithNext(workout.orderedExercises[0])
        workout.orderedExercises[0].orderedSets[0].completedAt = .now
        model.remove(workout.orderedExercises[0])
        XCTAssertEqual(names, ["Bent Over Row (Barbell)", "Bicep Curl (Dumbbell)"])
        XCTAssertEqual(model.removal?.title, "Bench Press (Barbell) removed")
        model.undoRemoval()
        XCTAssertEqual(names, ["Bench Press (Barbell)", "Bent Over Row (Barbell)", "Bicep Curl (Dumbbell)"])
        XCTAssertEqual(shape(workout.orderedExercises[0]), ["80x8✓", "80x8", "80x8"])
        XCTAssertEqual(workout.orderedExercises.map(\.supersetGroup), [1, 1, nil])
    }
}
