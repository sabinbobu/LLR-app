import XCTest
@testable import LLR

final class NutritionTargetsTests: XCTestCase {
    private func profile(_ gender: Gender? = .male, goal: TrainingGoal? = .gainStrength, activity: ActivityLevel = .moderate) -> NutritionTargets.Profile {
        .init(gender: gender, ageYears: 30, weightKg: 80, heightCm: 180, goal: goal, activity: activity)
    }

    func testMifflinStJeorKnownValues() {
        // 10·80 + 6.25·180 − 5·30 = 1775, then +5 male / −161 female.
        XCTAssertEqual(NutritionTargets.bmr(profile(.male)), 1780)
        XCTAssertEqual(NutritionTargets.bmr(profile(.female)), 1614)
        XCTAssertEqual(NutritionTargets.bmr(profile(.other)), 1697)
    }

    func testGoalAdjustsEnergy() {
        let maintain = NutritionTargets.auto(profile(goal: .gainStrength)).kcal
        XCTAssertEqual(maintain, (1780 * 1.55).rounded())
        XCTAssertEqual(NutritionTargets.auto(profile(goal: .fatLoss)).kcal, (1780 * 1.55 * 0.8).rounded())
        XCTAssertEqual(NutritionTargets.auto(profile(goal: .buildMuscle)).kcal, (1780 * 1.55 * 1.1).rounded())
    }

    func testProteinIsPerKilogram() {
        XCTAssertEqual(NutritionTargets.auto(profile()).proteinG, 128)
    }

    func testMacrosAddBackUpToCalories() {
        let m = NutritionTargets.auto(profile())
        XCTAssertEqual(m.proteinG * 4 + m.carbsG * 4 + m.fatG * 9, m.kcal, accuracy: 12)
    }

    func testOverridesWinPerMacro() {
        let auto = Macros(kcal: 2500, proteinG: 130, carbsG: 300, fatG: 70)
        let resolved = NutritionTargets.resolved(auto: auto, overrides: Macros(kcal: 0, proteinG: 180, carbsG: 0, fatG: 0))
        XCTAssertEqual(resolved, Macros(kcal: 2500, proteinG: 180, carbsG: 300, fatG: 70))
    }

    func testProfilePrefersLatestLoggedWeight() {
        let defaults = UserDefaults(suiteName: "NutritionTargetsTests")!
        defaults.removePersistentDomain(forName: "NutritionTargetsTests")
        defaults.set(90.0, forKey: StorageKey.bodyWeightKg)
        XCTAssertEqual(NutritionTargets.profile(defaults: defaults, latestWeightKg: 84).weightKg, 84)
        XCTAssertEqual(NutritionTargets.profile(defaults: defaults, latestWeightKg: nil).weightKg, 90)
    }
}
