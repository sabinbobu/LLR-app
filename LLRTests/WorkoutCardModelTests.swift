import SwiftData
import XCTest
@testable import LLR

@MainActor
final class WorkoutCardModelTests: XCTestCase {
    private var context: ModelContext!
    private var workout: Workout!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        workout = Workout()
        context.insert(workout)
    }

    private func add(_ name: String, muscle: String, sets: Int, kind: SetKind = .normal, ticked: Bool = true) {
        let exercise = Exercise(name: name, muscleGroup: muscle)
        context.insert(exercise)
        let entry = WorkoutExercise(order: workout.exercises.count)
        context.insert(entry)
        entry.exercise = exercise
        workout.exercises.append(entry)
        for index in 0..<sets {
            let set = SetEntry(order: index, weightKg: 50, reps: 8)
            set.kind = kind
            if ticked { set.completedAt = .now }
            context.insert(set)
            entry.sets.append(set)
        }
    }

    private func pushDay() {
        add("Stretching", muscle: "Cardio", sets: 1, kind: .warmup)
        add("Chest Press", muscle: "Chest", sets: 3)
        add("Cable Fly", muscle: "Chest", sets: 3)
        add("Shoulder Press", muscle: "Shoulders", sets: 3)
        add("Lateral Raise", muscle: "Shoulders", sets: 2)
        add("Pressdown", muscle: "Triceps", sets: 3)
        add("Leg Raise", muscle: "Abdominals", sets: 3)
    }

    func testCollapsedShowsFirstThreeWorkingExercisesAndSkipsTheWarmup() {
        pushDay()
        let model = WorkoutCardModel(workout: workout)
        XCTAssertEqual(model.visibleRows(expanded: false).map(\.name), ["Chest Press", "Cable Fly", "Shoulder Press"])
        XCTAssertEqual(model.hiddenCount, 4)
    }

    func testExpandedShowsEverythingInOrderWithTheWarmupFlagged() {
        pushDay()
        let rows = WorkoutCardModel(workout: workout).visibleRows(expanded: true)
        XCTAssertEqual(rows.count, 7)
        XCTAssertEqual(rows.first, WorkoutCardModel.Row(name: "Stretching", sets: 1, isWarmup: true))
        XCTAssertEqual(rows.filter(\.isWarmup).count, 1)
    }

    func testShortWorkoutHasNothingHidden() {
        add("Squat", muscle: "Quadriceps", sets: 4)
        add("Leg Press", muscle: "Quadriceps", sets: 3)
        XCTAssertEqual(WorkoutCardModel(workout: workout).hiddenCount, 0)
    }

    func testChipsAreTopThreeMusclesBySetCountAndIgnoreTheWarmup() {
        pushDay()
        // Chest 6, Shoulders 5, Triceps 3, Abdominals 3; Cardio is warm-up only. The tie keeps first-seen order.
        XCTAssertEqual(WorkoutCardModel(workout: workout).chips, ["Chest", "Shoulders", "Triceps"])
    }

    func testExercisesWithNoCompletedSetsAreLeftOut() {
        add("Squat", muscle: "Quadriceps", sets: 3)
        add("Skipped", muscle: "Calves", sets: 3, ticked: false)
        let model = WorkoutCardModel(workout: workout)
        XCTAssertEqual(model.rows.map(\.name), ["Squat"])
        XCTAssertEqual(model.chips, ["Quadriceps"])
    }

    func testSetCountIsCompletedSetsOnly() {
        add("Squat", muscle: "Quadriceps", sets: 3)
        workout.exercises[0].sets.last?.completedAt = nil
        XCTAssertEqual(WorkoutCardModel(workout: workout).rows.first?.sets, 2)
    }
}
