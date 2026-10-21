import SwiftData
import XCTest
@testable import LLR

@MainActor
final class HomeModelTests: XCTestCase {
    private var context: ModelContext!
    private var cal: Calendar!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 2
    }

    // Oct 2026: the 21st is a Wednesday.
    private func date(_ day: Int, hour: Int = 18) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    private func finished(_ name: String, day: Int, category: SessionCategory = .none, exercises: Int = 1) -> Workout {
        let workout = Workout(startedAt: date(day))
        workout.endedAt = date(day, hour: 19)
        workout.name = name
        workout.category = category
        context.insert(workout)
        for order in 0..<exercises {
            let entry = WorkoutExercise(order: order)
            context.insert(entry)
            workout.exercises.append(entry)
        }
        return workout
    }

    func testWeekRunsMondayToSundayWithStates() {
        let days = HomeModel.week(trained: [date(19)], now: date(21), calendar: cal)

        XCTAssertEqual(days.map(\.number), [19, 20, 21, 22, 23, 24, 25])
        XCTAssertEqual(days.map(\.letter), ["M", "T", "W", "T", "F", "S", "S"])
        XCTAssertEqual(days.map(\.state), [.trained, .rest, .today, .future, .future, .future, .future])
    }

    func testTrainingTodayReadsAsTrainedNotToday() {
        let days = HomeModel.week(trained: [date(21, hour: 7)], now: date(21), calendar: cal)

        XCTAssertEqual(days[2].state, .trained)
    }

    func testWeekFollowsTheCalendarsFirstWeekday() {
        cal.firstWeekday = 1
        let days = HomeModel.week(trained: [], now: date(21), calendar: cal)

        XCTAssertEqual(days.first?.number, 18)
        XCTAssertEqual(days.first?.letter, "S")
    }

    func testWorkoutCountOnlyCountsTheCurrentWeek() {
        let starts = [date(19), date(21, hour: 7), date(12), date(26)]

        XCTAssertEqual(HomeModel.workoutCount(in: starts, now: date(21), calendar: cal), 2)
    }

    func testNextUpIsTheSplitDoneLongestAgo() {
        let history = [finished("Pull Day", day: 19), finished("Push Day", day: 12), finished("Legs day", day: 9)]

        XCTAssertEqual(HomeModel.nextUp(history, now: date(21), calendar: cal)?.name, "Legs day")
    }

    func testNextUpUsesTheMostRecentSessionOfARepeatedSplit() {
        let history = [finished("Pull Day", day: 19), finished("Push Day", day: 15), finished("Pull Day", day: 12)]

        XCTAssertEqual(HomeModel.nextUp(history, now: date(21), calendar: cal)?.name, "Push Day")
    }

    func testNextUpFallsBackToCategoryAndIgnoresUnnamedWorkouts() {
        let history = [finished("", day: 19), finished("", day: 15, category: .push)]

        XCTAssertEqual(HomeModel.nextUp(history, now: date(21), calendar: cal).flatMap(HomeModel.splitName), "Push")
    }

    func testNextUpIgnoresOldEmptyAndUnfinishedWorkouts() {
        let old = finished("Old Split", day: 1)
        let empty = finished("Empty", day: 18, exercises: 0)
        let running = finished("Running", day: 19)
        running.endedAt = nil

        XCTAssertNil(HomeModel.nextUp([old], now: date(31), calendar: cal))
        XCTAssertNil(HomeModel.nextUp([empty, running], now: date(21), calendar: cal))
    }

    func testCardRowsMuteWarmupsAndSkipExercisesWithNoCompletedSets() {
        let workout = Workout(startedAt: date(19))
        context.insert(workout)
        func add(_ name: String, group: String, kinds: [SetKind?]) {
            let exercise = Exercise(name: name, muscleGroup: group)
            context.insert(exercise)
            let entry = WorkoutExercise(order: workout.exercises.count)
            context.insert(entry)
            entry.exercise = exercise
            workout.exercises.append(entry)
            for (order, kind) in kinds.enumerated() {
                let set = SetEntry(order: order, weightKg: 50, reps: 5)
                context.insert(set)
                set.kind = kind ?? .normal
                set.completedAt = kind == nil ? nil : date(19)
                entry.sets.append(set)
            }
        }
        add("Stretching", group: MuscleGroup.cardio.rawValue, kinds: [.warmup])
        add("Lat Pulldown", group: MuscleGroup.lats.rawValue, kinds: [.normal, .normal, .normal])
        add("Skipped", group: MuscleGroup.chest.rawValue, kinds: [nil])

        XCTAssertEqual(workout.cardRows.map(\.name), ["Stretching", "Lat Pulldown"])
        XCTAssertEqual(workout.cardRows.map(\.isWarmup), [true, false])
        XCTAssertEqual(workout.cardRows.map(\.sets), [1, 3])
        XCTAssertEqual(workout.cardMuscles, [MuscleGroup.lats.rawValue])
    }
}
