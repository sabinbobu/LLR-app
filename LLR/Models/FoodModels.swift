import Foundation
import SwiftData

enum Meal: String, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "sun.max"
        case .dinner: "moon.stars"
        case .snack: "carrot"
        }
    }

    /// The review screen's default, so the common case needs no extra tap.
    static func suggested(for date: Date, calendar: Calendar = .current) -> Meal {
        switch calendar.component(.hour, from: date) {
        case 4..<11: .breakfast
        case 11..<16: .lunch
        case 16..<22: .dinner
        default: .snack
        }
    }
}

enum FoodSource: String {
    case ai, manual
}

/// One food item, not one meal: a plate the AI splits into three items becomes three rows sharing
/// `loggedAt` and `meal`, so each can be corrected or deleted without a parent model.
@Model
final class FoodEntry {
    var id: UUID
    var loggedAt: Date
    var mealRaw: String
    var name: String
    var grams: Double?
    var kcal: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var sourceRaw: String
    var aiModel: String?
    @Attribute(.externalStorage) var photoData: Data?

    init(
        name: String, meal: Meal, kcal: Double, proteinG: Double, carbsG: Double, fatG: Double,
        grams: Double? = nil, source: FoodSource = .manual, aiModel: String? = nil,
        photoData: Data? = nil, loggedAt: Date = .now
    ) {
        self.id = UUID()
        self.loggedAt = loggedAt
        self.mealRaw = meal.rawValue
        self.name = name
        self.grams = grams
        self.kcal = kcal
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.sourceRaw = source.rawValue
        self.aiModel = aiModel
        self.photoData = photoData
    }
}

extension FoodEntry {
    var meal: Meal {
        get { Meal(rawValue: mealRaw) ?? .snack }
        set { mealRaw = newValue.rawValue }
    }

    var source: FoodSource { FoodSource(rawValue: sourceRaw) ?? .manual }
}
