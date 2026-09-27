import Foundation

enum DailyNutrition {
    static func entries(_ all: [FoodEntry], on day: Date, calendar: Calendar = .current) -> [FoodEntry] {
        all.filter { calendar.isDate($0.loggedAt, inSameDayAs: day) }
    }

    static func total(_ entries: [FoodEntry]) -> Macros {
        entries.reduce(.zero) { $0 + $1.macros }
    }

    static func byMeal(_ entries: [FoodEntry]) -> [(meal: Meal, entries: [FoodEntry])] {
        Meal.allCases.compactMap { meal in
            let items = entries.filter { $0.meal == meal }.sorted { $0.loggedAt < $1.loggedAt }
            return items.isEmpty ? nil : (meal, items)
        }
    }

    /// Unclamped on purpose: the bars draw the part past 1.0 as an over-target segment.
    static func progress(_ value: Double, of target: Double) -> Double {
        target > 0 ? max(0, value / target) : 0
    }
}

extension FoodEntry {
    var macros: Macros { Macros(kcal: kcal, proteinG: proteinG, carbsG: carbsG, fatG: fatG) }
}
