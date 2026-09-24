import Foundation

enum StorageKey {
    static let hasOnboarded = "hasOnboarded"
    static let weightUnit = "weightUnit"
    static let gender = "gender"
    static let birthday = "birthday"
    static let bodyWeightKg = "bodyWeightKg"
    static let heightCm = "heightCm"
    static let heightUnit = "heightUnit"
    static let goal = "goal"
    static let experience = "experience"
    static let restSeconds = "restSeconds"
    // One per unit: a 45 lb bar is not 20 kg, so converting a single stored value would be wrong.
    static let barKg = "barKg"
    static let barLbs = "barLbs"
}

extension WeightUnit {
    /// For code outside views, which can't use @AppStorage.
    static var stored: WeightUnit {
        UserDefaults.standard.string(forKey: StorageKey.weightUnit).flatMap(WeightUnit.init(rawValue:)) ?? .kg
    }
}

enum Gender: String, CaseIterable, Identifiable {
    case male, female, other

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .male: "♂"
        case .female: "♀"
        case .other: "⚥"
        }
    }
}

enum HeightUnit: String, CaseIterable, Identifiable {
    case cm, ftIn

    var id: String { rawValue }
    var title: String { self == .cm ? "Centimeters" : "Feet and Inches" }
}

enum TrainingGoal: String, CaseIterable, Identifiable {
    case buildMuscle, gainStrength, fatLoss

    var id: String { rawValue }
    var title: String {
        switch self {
        case .buildMuscle: "Build Muscle"
        case .gainStrength: "Gain Strength"
        case .fatLoss: "Fat Loss"
        }
    }
    var icon: String {
        switch self {
        case .buildMuscle: "figure.strengthtraining.traditional"
        case .gainStrength: "dumbbell"
        case .fatLoss: "scalemass"
        }
    }
}

enum Experience: String, CaseIterable, Identifiable {
    case beginner, intermediate, advanced

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var detail: String {
        switch self {
        case .beginner: "0-1 year"
        case .intermediate: "1-3 years"
        case .advanced: "3+ years"
        }
    }
}
