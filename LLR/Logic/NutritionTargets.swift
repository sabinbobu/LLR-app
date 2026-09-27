import Foundation

struct Macros: Equatable {
    var kcal: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double

    static let zero = Macros(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0)

    static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(kcal: lhs.kcal + rhs.kcal, proteinG: lhs.proteinG + rhs.proteinG,
               carbsG: lhs.carbsG + rhs.carbsG, fatG: lhs.fatG + rhs.fatG)
    }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary, light, moderate, high

    var id: String { rawValue }
    var title: String {
        switch self {
        case .sedentary: "Sedentary"
        case .light: "Light (1–3 sessions/wk)"
        case .moderate: "Moderate (3–5 sessions/wk)"
        case .high: "High (6–7 sessions/wk)"
        }
    }
    /// The standard multipliers applied to BMR to estimate total daily energy expenditure.
    var factor: Double {
        switch self {
        case .sedentary: 1.2
        case .light: 1.375
        case .moderate: 1.55
        case .high: 1.725
        }
    }
}

/// Daily targets from the profile onboarding already collects.
///
/// - BMR: Mifflin-St Jeor (Mifflin et al. 1990, Am J Clin Nutr 51(2):241–7).
/// - Protein: 1.6 g/kg; Morton et al. 2018 (Br J Sports Med 52(6):376–84) saw gains plateau near 1.62.
/// - Fat 25% of energy, carbs the remainder: a common default, not a finding. It is editable.
enum NutritionTargets {
    struct Profile {
        var gender: Gender?
        var ageYears: Double
        var weightKg: Double
        var heightCm: Double
        var goal: TrainingGoal?
        var activity: ActivityLevel
    }

    static let proteinPerKg = 1.6
    static let fatEnergyShare = 0.25

    static func bmr(_ p: Profile) -> Double {
        let base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.ageYears
        switch p.gender {
        case .male: return base + 5
        case .female: return base - 161
        // The equation only has sex-specific constants; midway is the least-wrong neutral choice.
        case .other, nil: return base - 78
        }
    }

    static func goalAdjustment(_ goal: TrainingGoal?) -> Double {
        switch goal {
        case .fatLoss: 0.8
        case .buildMuscle: 1.1
        case .gainStrength, nil: 1.0
        }
    }

    static func auto(_ p: Profile) -> Macros {
        let kcal = (bmr(p) * p.activity.factor * goalAdjustment(p.goal)).rounded()
        let protein = (proteinPerKg * p.weightKg).rounded()
        let fat = (kcal * fatEnergyShare / 9).rounded()
        let carbs = max(0, ((kcal - protein * 4 - fat * 9) / 4).rounded())
        return Macros(kcal: kcal, proteinG: protein, carbsG: carbs, fatG: fat)
    }

    /// Any override > 0 wins over the computed value for that one macro.
    static func resolved(auto: Macros, overrides: Macros) -> Macros {
        func pick(_ o: Double, _ a: Double) -> Double { o > 0 ? o : a }
        return Macros(kcal: pick(overrides.kcal, auto.kcal), proteinG: pick(overrides.proteinG, auto.proteinG),
                      carbsG: pick(overrides.carbsG, auto.carbsG), fatG: pick(overrides.fatG, auto.fatG))
    }
}
