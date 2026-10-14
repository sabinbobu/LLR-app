import SwiftData
import XCTest
@testable import LLR

@MainActor
final class WorkoutTabModelTests: XCTestCase {
    private var context: ModelContext!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    private func routine(_ name: String, daysAgo: Int, section: WorkoutSection = .gym) -> Routine {
        let routine = Routine()
        routine.name = name
        routine.section = section
        routine.createdAt = Date(timeIntervalSince1970: 1_700_000_000 - Double(daysAgo) * 86_400)
        context.insert(routine)
        return routine
    }

    private func workout(_ name: String, daysAgo: Int, finished: Bool = true, sectionRaw: String = "gym",
                         withExercise: Bool = true) -> Workout {
        let workout = Workout(startedAt: Date(timeIntervalSince1970: 1_700_000_000 - Double(daysAgo) * 86_400))
        workout.name = name
        workout.sectionRaw = sectionRaw
        if finished { workout.endedAt = workout.startedAt.addingTimeInterval(3600) }
        context.insert(workout)
        if withExercise {
            let entry = WorkoutExercise(order: 0)
            context.insert(entry)
            workout.exercises.append(entry)
        }
        return workout
    }

    func testRecentRoutinesAreNewestFirstGymOnlyAndCappedAtFive() {
        var all: [Routine] = []
        for day in 0..<7 { all.append(routine("R\(day)", daysAgo: day)) }
        all.append(routine("Back", daysAgo: 0, section: .kineto))
        let names = WorkoutTabModel.recentRoutines(all).map(\.name)
        XCTAssertEqual(names, ["R0", "R1", "R2", "R3", "R4"])
    }

    func testRepeatCandidatesAreTheLastThreeFinishedGymWorkoutsWithExercises() {
        let all = [
            workout("Old", daysAgo: 9),
            workout("A", daysAgo: 1),
            workout("Open", daysAgo: 0, finished: false),
            workout("Run", daysAgo: 2, sectionRaw: "run", withExercise: false),
            workout("Empty", daysAgo: 2, withExercise: false),
            workout("B", daysAgo: 3),
            workout("C", daysAgo: 4),
        ]
        XCTAssertEqual(WorkoutTabModel.repeatCandidates(all).map(\.name), ["A", "B", "C"])
    }

    func testGettingStartedShowsOnlyBeforeTheFirstFinishedWorkout() {
        XCTAssertTrue(WorkoutTabModel.showsGettingStarted(finishedGymWorkouts: 0))
        XCTAssertFalse(WorkoutTabModel.showsGettingStarted(finishedGymWorkouts: 1))
    }
}
