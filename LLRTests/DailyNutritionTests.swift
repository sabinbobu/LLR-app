import SwiftData
import XCTest
@testable import LLR

@MainActor
final class DailyNutritionTests: XCTestCase {
    private let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!

    private func entry(_ meal: Meal, kcal: Double, protein: Double = 0, at date: Date) -> FoodEntry {
        FoodEntry(name: "x", meal: meal, kcal: kcal, proteinG: protein, carbsG: 0, fatG: 0, loggedAt: date)
    }

    func testOnlyTheSameDayCounts() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: noon)!
        let all = [entry(.lunch, kcal: 500, at: noon), entry(.lunch, kcal: 700, at: yesterday)]
        XCTAssertEqual(DailyNutrition.total(DailyNutrition.entries(all, on: noon)).kcal, 500)
    }

    func testGroupsByMealInMealOrderSkippingEmpty() {
        let entries = [entry(.dinner, kcal: 600, at: noon), entry(.breakfast, kcal: 300, at: noon), entry(.breakfast, kcal: 100, at: noon)]
        let groups = DailyNutrition.byMeal(entries)
        XCTAssertEqual(groups.map(\.meal), [.breakfast, .dinner])
        XCTAssertEqual(DailyNutrition.total(groups[0].entries).kcal, 400)
    }

    func testProgressIsUnclampedAndSafeWithNoTarget() {
        XCTAssertEqual(DailyNutrition.progress(150, of: 100), 1.5)
        XCTAssertEqual(DailyNutrition.progress(50, of: 0), 0)
    }

    func testMealSuggestionFollowsTimeOfDay() {
        func at(_ hour: Int) -> Date { Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: noon)! }
        XCTAssertEqual(Meal.suggested(for: at(8)), .breakfast)
        XCTAssertEqual(Meal.suggested(for: at(13)), .lunch)
        XCTAssertEqual(Meal.suggested(for: at(19)), .dinner)
        XCTAssertEqual(Meal.suggested(for: at(23)), .snack)
    }

    func testFoodEntryRoundTripsThroughAContainer() throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            BodyMeasurement.self, ProgressPhoto.self, FoodEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        context.insert(FoodEntry(name: "Oats", meal: .breakfast, kcal: 380, proteinG: 13, carbsG: 67, fatG: 7,
                                 grams: 100, source: .ai, aiModel: "m", photoData: Data([1, 2, 3])))
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<FoodEntry>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].meal, .breakfast)
        XCTAssertEqual(fetched[0].source, .ai)
        XCTAssertEqual(fetched[0].photoData, Data([1, 2, 3]))
    }
}
