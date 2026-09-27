import Foundation

extension NutritionTargets {
    /// Builds the profile from onboarding answers, preferring the most recent logged bodyweight
    /// over the one typed at onboarding, which goes stale as soon as the user cuts or bulks.
    static func profile(defaults: UserDefaults = .standard, latestWeightKg: Double?, now: Date = .now) -> Profile {
        let birthday = defaults.object(forKey: StorageKey.birthday) as? Double ?? 820_454_400
        let age = max(14, now.timeIntervalSince(Date(timeIntervalSince1970: birthday)) / (365.25 * 86_400))
        let onboardingWeight = defaults.object(forKey: StorageKey.bodyWeightKg) as? Double ?? 70
        let height = defaults.object(forKey: StorageKey.heightCm) as? Int ?? 170
        return Profile(
            gender: defaults.string(forKey: StorageKey.gender).flatMap(Gender.init(rawValue:)),
            ageYears: age,
            weightKg: latestWeightKg ?? onboardingWeight,
            heightCm: Double(height),
            goal: defaults.string(forKey: StorageKey.goal).flatMap(TrainingGoal.init(rawValue:)),
            activity: defaults.string(forKey: StorageKey.fuelActivity).flatMap(ActivityLevel.init(rawValue:)) ?? .moderate
        )
    }

    static func overrides(defaults: UserDefaults = .standard) -> Macros {
        Macros(kcal: defaults.double(forKey: StorageKey.fuelKcalOverride),
               proteinG: defaults.double(forKey: StorageKey.fuelProteinOverride),
               carbsG: defaults.double(forKey: StorageKey.fuelCarbsOverride),
               fatG: defaults.double(forKey: StorageKey.fuelFatOverride))
    }
}
