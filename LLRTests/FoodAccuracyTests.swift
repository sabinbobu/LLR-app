import XCTest
@testable import LLR

/// Accuracy harness for Fuel estimates. The network part runs only when OPENROUTER_KEY is set
/// (optionally OPENROUTER_MODEL), so the default test run never calls out.
/// Run: OPENROUTER_KEY=sk-or-... xcodebuild -scheme LLR -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:LLRTests/FoodAccuracyTests
final class FoodAccuracyTests: XCTestCase {
    struct Macros { var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0 }

    private struct Fixture: Decodable {
        struct Food: Decodable {
            struct Per100: Decodable { let kcal, protein_g, carbs_g, fat_g: Double }
            let source: String
            let per100g: Per100
        }
        struct Meal: Decodable {
            struct Ingredient: Decodable { let food: String; let grams: Double }
            let id: Int
            let name, description, vagueDescription: String
            let ingredients: [Ingredient]
        }
        let foods: [String: Food]
        let meals: [Meal]

        func truth(_ meal: Meal) -> Macros {
            meal.ingredients.reduce(into: Macros()) { total, item in
                let f = foods[item.food]!.per100g, k = item.grams / 100
                total.kcal += f.kcal * k; total.protein += f.protein_g * k
                total.carbs += f.carbs_g * k; total.fat += f.fat_g * k
            }
        }
    }

    private func load() throws -> Fixture {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "fuel-meals", withExtension: "json"))
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    func testFixtureIsComplete() throws {
        let fixture = try load()
        XCTAssertEqual(fixture.meals.count, 20)
        XCTAssertTrue(fixture.foods.values.allSatisfy { $0.source.hasPrefix("USDA FoodData Central: ") })
        for meal in fixture.meals {
            XCTAssertTrue(meal.ingredients.allSatisfy { fixture.foods[$0.food] != nil }, meal.name)
            XCTAssertGreaterThan(fixture.truth(meal).kcal, 100, meal.name)
        }
    }

    func testPercentErrorIgnoresTinyDenominators() {
        XCTAssertEqual(Self.ape(estimate: 110, truth: 100), 10, accuracy: 0.001)
        XCTAssertEqual(Self.ape(estimate: 3, truth: 0.5), 0, accuracy: 0.001, "sub-gram macros are noise")
    }

    /// Prints per-meal and mean absolute percentage error; copy the output into docs/fuel-accuracy.md.
    func testLiveAccuracyReport() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let key = env["OPENROUTER_KEY"], !key.isEmpty else { throw XCTSkip("Set OPENROUTER_KEY to run the live accuracy report") }
        let model = env["OPENROUTER_MODEL"].flatMap { $0.isEmpty ? nil : $0 } ?? OpenRouterClient.defaultModel
        let fixture = try load()
        for (label, pick) in [("stated grams", \Fixture.Meal.description), ("vague portions", \Fixture.Meal.vagueDescription)] {
            var errors: [[Double]] = []
            print("== \(model) / \(label)")
            for meal in fixture.meals {
                let result = try await OpenRouterClient.analyze(.text(meal[keyPath: pick]), key: key, model: model)
                let got = result.items.reduce(into: Macros()) {
                    $0.kcal += $1.kcal; $0.protein += $1.proteinG; $0.carbs += $1.carbsG; $0.fat += $1.fatG
                }
                let t = fixture.truth(meal)
                let e = [Self.ape(estimate: got.kcal, truth: t.kcal), Self.ape(estimate: got.protein, truth: t.protein),
                         Self.ape(estimate: got.carbs, truth: t.carbs), Self.ape(estimate: got.fat, truth: t.fat)]
                errors.append(e)
                print(String(format: "%2d %-26@ kcal %5.1f%%  P %5.1f%%  C %5.1f%%  F %5.1f%%", meal.id, meal.name as NSString, e[0], e[1], e[2], e[3]))
            }
            let mean = (0..<4).map { i in errors.map { $0[i] }.reduce(0, +) / Double(errors.count) }
            print(String(format: "MEAN kcal %.1f%%  P %.1f%%  C %.1f%%  F %.1f%%", mean[0], mean[1], mean[2], mean[3]))
        }
    }

    /// Macros under 1 g are skipped (reported as 0) because a 0.4 g vs 1.2 g miss is rounding, not error.
    static func ape(estimate: Double, truth: Double) -> Double {
        guard truth >= 1 else { return 0 }
        return abs(estimate - truth) / truth * 100
    }
}
