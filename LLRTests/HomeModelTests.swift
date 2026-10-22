import SwiftData
import XCTest
@testable import LLR

@MainActor
final class HomeModelTests: XCTestCase {
    private var context: ModelContext!
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    private func routine(_ name: String, createdDaysAgo: Int = 0, section: WorkoutSection = .gym, exercises: Int = 1) -> Routine {
        let routine = Routine()
        routine.name = name
        routine.section = section
        routine.createdAt = base.addingTimeInterval(-Double(createdDaysAgo) * 86_400)
        context.insert(routine)
        for index in 0..<exercises {
            let entry = RoutineExercise(order: index)
            context.insert(entry)
            routine.exercises.append(entry)
        }
        return routine
    }

    private func workout(_ name: String, daysAgo: Int, finished: Bool = true, sectionRaw: String = "gym") -> Workout {
        let workout = Workout(startedAt: base.addingTimeInterval(-Double(daysAgo) * 86_400))
        workout.name = name
        workout.sectionRaw = sectionRaw
        if finished { workout.endedAt = workout.startedAt.addingTimeInterval(3600) }
        context.insert(workout)
        return workout
    }

    func testNextUpIsTheRoutineDoneLongestAgo() {
        let pull = routine("Pull Day"), push = routine("Push Day"), legs = routine("Legs day")
        let history = [workout("Pull Day", daysAgo: 2), workout("Push Day", daysAgo: 9), workout("Legs day", daysAgo: 12)]
        XCTAssertEqual(HomeModel.nextUp(routines: [pull, push, legs], workouts: history)?.name, "Legs day")
    }

    func testNeverDoneRoutineComesBeforeAnyDoneOne() {
        let done = routine("Pull Day"), fresh = routine("Arms")
        let history = [workout("Pull Day", daysAgo: 30)]
        XCTAssertEqual(HomeModel.nextUp(routines: [done, fresh], workouts: history)?.name, "Arms")
    }

    func testNeverDoneTieGoesToTheNewestRoutine() {
        let older = routine("A", createdDaysAgo: 10), newer = routine("B", createdDaysAgo: 1)
        XCTAssertEqual(HomeModel.nextUp(routines: [older, newer], workouts: [])?.name, "B")
    }

    func testNextUpIgnoresUnfinishedKinetoRunAndEmptyRoutines() {
        let pull = routine("Pull Day"), back = routine("Back", section: .kineto), empty = routine("Empty", exercises: 0)
        let history = [
            workout("Pull Day", daysAgo: 1, finished: false),
            workout("Pull Day", daysAgo: 20, sectionRaw: "run"),
        ]
        // The open and run workouts don't count as doing Pull Day, so it is still never done; the
        // other two routines are not eligible at all.
        XCTAssertEqual(HomeModel.nextUp(routines: [back, empty, pull], workouts: history)?.name, "Pull Day")
        XCTAssertNil(HomeModel.nextUp(routines: [back, empty], workouts: history))
    }

    func testNextUpIsNilWithNoRoutines() {
        XCTAssertNil(HomeModel.nextUp(routines: [], workouts: [workout("Pull Day", daysAgo: 1)]))
    }

    // MARK: week

    private func calendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ day: Int) -> Date {
        // October 2026: the 19th is a Monday and the 21st the Wednesday of the design mockup.
        calendar(firstWeekday: 2).date(from: DateComponents(year: 2026, month: 10, day: day, hour: 12))!
    }

    func testWeekMatchesTheDesignMockup() {
        let cal = calendar(firstWeekday: 2)
        let week = HomeModel.week(starts: [date(19)], now: date(21), calendar: cal)
        XCTAssertEqual(week.days.map(\.number), [19, 20, 21, 22, 23, 24, 25])
        XCTAssertEqual(week.days.map(\.letter), ["M", "T", "W", "T", "F", "S", "S"])
        XCTAssertEqual(week.days.map(\.trained), [true, false, false, false, false, false, false])
        XCTAssertEqual(week.days.map(\.isToday), [false, false, true, false, false, false, false])
        XCTAssertEqual(week.days.map(\.isFuture), [false, false, false, true, true, true, true])
        XCTAssertEqual(week.workoutCount, 1)
    }

    func testWeekFollowsTheCalendarsFirstWeekday() {
        let sunday = calendar(firstWeekday: 1)
        let week = HomeModel.week(starts: [], now: date(21), calendar: sunday)
        XCTAssertEqual(week.days.first?.number, 18)
        XCTAssertEqual(week.days.first?.letter, "S")
    }

    func testWorkoutCountCountsSessionsNotDaysAndSkipsOtherWeeks() {
        let cal = calendar(firstWeekday: 2)
        let starts = [date(19), date(19).addingTimeInterval(3600), date(20), date(12)]
        let week = HomeModel.week(starts: starts, now: date(21), calendar: cal)
        XCTAssertEqual(week.workoutCount, 3)
        XCTAssertEqual(week.days.filter(\.trained).count, 2)
    }

    // MARK: totals, categories, month

    func testTotalsSumDurationAndVolume() {
        let sessions = [HomeModel.Session(start: date(19), duration: 3600, volumeKg: 5000),
                        HomeModel.Session(start: date(20), duration: 1650, volumeKg: 0)]
        XCTAssertEqual(HomeModel.totals(sessions), HomeModel.Totals(count: 2, duration: 5250, volumeKg: 5000))
        XCTAssertEqual(HomeModel.totals([]), HomeModel.Totals(count: 0, duration: 0, volumeKg: 0))
    }

    func testCategoryByDayLatestCategorisedWinsAndUncategorisedIsAbsent() {
        let cal = calendar(firstWeekday: 2)
        let result = HomeModel.categoryByDay([
            (date(19), .push), (date(19).addingTimeInterval(3600), .pull), (date(20), .none),
        ], calendar: cal)
        XCTAssertEqual(result[cal.startOfDay(for: date(19))], .pull)
        XCTAssertNil(result[cal.startOfDay(for: date(20))])
    }

    func testWeekDaysCarryTheirCategory() {
        let cal = calendar(firstWeekday: 2)
        let cats = HomeModel.categoryByDay([(date(19), .legs)], calendar: cal)
        let week = HomeModel.week(starts: [date(19)], categories: cats, now: date(21), calendar: cal)
        XCTAssertEqual(week.days.map(\.category), [.legs, .none, .none, .none, .none, .none, .none])
    }

    func testWeekdayLettersStartOnTheFirstWeekday() {
        XCTAssertEqual(HomeModel.weekdayLetters(calendar: calendar(firstWeekday: 2)).first, "M")
        XCTAssertEqual(HomeModel.weekdayLetters(calendar: calendar(firstWeekday: 1)).first, "S")
    }

    func testMonthCellsPadToTheFirstWeekdayAndCoverEveryDay() {
        // 1 October 2026 is a Thursday: three blanks after Monday, four after Sunday.
        let monday = HomeModel.monthCells(month: date(21), starts: [], now: date(21), calendar: calendar(firstWeekday: 2))
        XCTAssertEqual(monday.prefix(while: { $0 == nil }).count, 3)
        XCTAssertEqual(monday.compactMap { $0 }.count, 31)
        let sunday = HomeModel.monthCells(month: date(21), starts: [], now: date(21), calendar: calendar(firstWeekday: 1))
        XCTAssertEqual(sunday.prefix(while: { $0 == nil }).count, 4)
    }

    func testMonthCellsMarkTrainedTodayFutureAndCategory() {
        let cal = calendar(firstWeekday: 2)
        let cats = HomeModel.categoryByDay([(date(19), .push)], calendar: cal)
        let days = HomeModel.monthCells(month: date(21), starts: [date(19), date(3)], categories: cats, now: date(21), calendar: cal).compactMap { $0 }
        XCTAssertEqual(days.filter(\.trained).map(\.number), [3, 19])
        XCTAssertEqual(days.first(where: \.isToday)?.number, 21)
        XCTAssertEqual(days.filter(\.isFuture).count, 10)
        XCTAssertEqual(days[18].category, .push)
    }

    func testMonthCellsIgnoreWorkoutsFromOtherMonths() {
        let cal = calendar(firstWeekday: 2)
        let september = cal.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 12))!
        let days = HomeModel.monthCells(month: date(21), starts: [september], now: date(21), calendar: cal).compactMap { $0 }
        XCTAssertTrue(days.allSatisfy { !$0.trained })
    }
}
