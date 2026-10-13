import SwiftData
import XCTest
@testable import LLR

@MainActor
final class SessionCategoryTests: XCTestCase {
    func testRawRoundTripAndUnknownReadsAsNone() {
        for category in SessionCategory.allCases { XCTAssertEqual(SessionCategory(raw: category.rawValue), category) }
        XCTAssertEqual(SessionCategory(raw: "cardio-blast"), .none)
        XCTAssertEqual(SessionCategory(raw: ""), .none)
    }

    func testLibraryDayNamesMapOnlyWhenUnambiguous() {
        XCTAssertEqual(SessionCategory.infer(fromDayName: "Day 2 · Legs & Abs"), .legs)
        XCTAssertEqual(SessionCategory.infer(fromDayName: "Push A"), .push)
        XCTAssertEqual(SessionCategory.infer(fromDayName: "Pull Day"), .pull)
        XCTAssertEqual(SessionCategory.infer(fromDayName: "Push/Pull"), .none)
        XCTAssertEqual(SessionCategory.infer(fromDayName: "Workout A"), .none)
        XCTAssertEqual(SessionCategory.infer(fromDayName: "Pushup Practice"), .none, "whole words only")
    }

    func testStartingFromACategorisedRoutineOrWorkoutInheritsIt() throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let routine = Routine(name: "Push A")
        routine.category = .push
        context.insert(routine)
        let started = WorkoutFactory.start(routine: routine, in: context)
        XCTAssertEqual(started.category, .push)

        let repeated = WorkoutFactory.start(copying: started, in: context)
        XCTAssertEqual(repeated.category, .push)
        XCTAssertEqual(Workout().category, .none, "existing rows default to uncategorised")
        XCTAssertEqual(repeated.section, .gym, "category never touches the history section")
    }
}
