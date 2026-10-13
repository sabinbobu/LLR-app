import SwiftData
import XCTest
@testable import LLR

@MainActor
final class StretchRoutinesTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func testOnlyPushPullLegsHaveACooldown() {
        for category in [SessionCategory.push, .pull, .legs] { XCTAssertNotNil(StretchRoutines.moves(for: category)) }
        XCTAssertNil(StretchRoutines.moves(for: .yoga))
        XCTAssertNil(StretchRoutines.moves(for: .none))
    }

    func testOfferDependsOnCategorySectionAndNotBeingACooldownItself() {
        let workout = Workout()
        XCTAssertFalse(StretchRoutines.offersCooldown(after: workout))
        workout.category = .legs
        XCTAssertTrue(StretchRoutines.offersCooldown(after: workout))
        workout.name = "Legs Cooldown"
        XCTAssertFalse(StretchRoutines.offersCooldown(after: workout))
        workout.name = ""
        workout.category = .yoga
        XCTAssertFalse(StretchRoutines.offersCooldown(after: workout))
    }

    func testCooldownIsASeparateTimedWorkoutThatCountsForNothing() throws {
        let context = try makeContext()
        for move in StretchRoutines.moves(for: .push)! { context.insert(Exercise(name: move.exercise, muscleGroup: "Chest")) }
        let session = Workout()
        session.category = .push
        context.insert(session)

        let cooldown = try XCTUnwrap(StretchRoutines.startCooldown(after: session, in: context))

        XCTAssertNotEqual(cooldown.id, session.id)
        XCTAssertEqual(cooldown.title, "Push Cooldown")
        XCTAssertEqual(cooldown.category, .push)
        XCTAssertEqual(session.exercises.count, 0, "the finished workout is not appended to")
        let sets = cooldown.orderedExercises.flatMap(\.orderedSets)
        XCTAssertFalse(sets.isEmpty)
        XCTAssertTrue(sets.allSatisfy { $0.kind == .warmup && $0.durationSeconds == StretchRoutines.holdSeconds })
        XCTAssertTrue(cooldown.orderedExercises.allSatisfy(\.isDurationBased))
    }

    func testEveryStretchExistsInTheBundledLibrary() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "exercises", withExtension: "json")
            ?? Bundle.main.url(forResource: "exercises", withExtension: "json"))
        let names = Set(try ExerciseLibrary.parseSeeds(Data(contentsOf: url)).map(\.name))
        for category in [SessionCategory.push, .pull, .legs] {
            for move in StretchRoutines.moves(for: category)! {
                XCTAssertTrue(names.contains(move.exercise), move.exercise)
                XCTAssertTrue(TimedWarmup.isTimedByDefault(muscleGroup: "x", name: move.exercise))
            }
        }
    }
}
