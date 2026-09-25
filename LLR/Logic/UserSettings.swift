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
    // Kineto gate: cleared version/date re-ask the gate whenever the catalog content changes.
    static let kinetoClearedVersion = "kinetoClearedVersion"
    static let kinetoClearedAt = "kinetoClearedAt"
    static let kinetoDirection = "kinetoDirection"
    static let kinetoPainRule = "kinetoPainRule"
}

/// The direction the physiotherapist has identified as helpful, set once at the Kineto gate.
/// Picking a catalog exercise tagged the *other* single direction shows a warning — never hidden,
/// per Long 2004 vs. Dettori 1995 (see the plan's disagreement table).
enum KinetoDirectionPreference: String, CaseIterable, Identifiable {
    case notAssessed, matchesFlexion, matchesExtension, noPreference

    var id: String { rawValue }
    var title: String {
        switch self {
        case .notAssessed: "Not assessed yet"
        case .matchesFlexion: "Flexion helps"
        case .matchesExtension: "Extension helps"
        case .noPreference: "No preference set"
        }
    }

    func warns(for direction: KinetoCatalog.Direction) -> Bool {
        switch self {
        case .notAssessed, .noPreference: false
        case .matchesFlexion: direction == .extension
        case .matchesExtension: direction == .flexion
        }
    }
}

/// AAOS ("don't feel pain during an exercise") vs. Plymouth ("won't make it worse, even with a
/// bit of discomfort at first") — the app defaults to the stricter rule and lets the physio switch it.
enum KinetoPainRule: String, CaseIterable, Identifiable {
    case stopOnPain, mildDiscomfortOK

    var id: String { rawValue }
    var title: String {
        switch self {
        case .stopOnPain: "Stop if it hurts"
        case .mildDiscomfortOK: "Mild discomfort is OK"
        }
    }
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
