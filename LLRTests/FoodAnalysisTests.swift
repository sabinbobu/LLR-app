import XCTest
@testable import LLR

final class FoodAnalysisTests: XCTestCase {
    private let clean = #"{"items":[{"name":"Chicken breast","grams":200,"kcal":330,"protein_g":62,"carbs_g":0,"fat_g":7.2}],"confidence":"medium"}"#

    func testParsesCleanJSON() throws {
        let result = try FoodAnalysis.parseContent(clean)
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items[0].name, "Chicken breast")
        XCTAssertEqual(result.items[0].proteinG, 62)
        XCTAssertEqual(result.confidence, .medium)
    }

    func testParsesFencedJSONWithProse() throws {
        let content = "Here is my estimate:\n```json\n\(clean)\n```\nEnjoy!"
        XCTAssertEqual(try FoodAnalysis.parseContent(content).items.count, 1)
    }

    func testMalformedContentThrows() {
        XCTAssertThrowsError(try FoodAnalysis.parseContent("I can't see any food.")) {
            XCTAssertEqual($0 as? FoodAnalysis.ParseError, .noJSON)
        }
        XCTAssertThrowsError(try FoodAnalysis.parseContent(#"{"items":[]}"#)) {
            XCTAssertEqual($0 as? FoodAnalysis.ParseError, .noItems)
        }
    }

    func testNegativeValuesAreRejected() {
        let bad = #"{"items":[{"name":"Rice","grams":150,"kcal":-5,"protein_g":4,"carbs_g":42,"fat_g":0.4}]}"#
        XCTAssertThrowsError(try FoodAnalysis.parseContent(bad)) {
            XCTAssertEqual($0 as? FoodAnalysis.ParseError, .invalidValue("Rice"))
        }
    }

    func testKcalMismatchIsFlagged() {
        let ok = FoodAnalysis.Item(name: "Rice", grams: 150, kcal: 195, proteinG: 4, carbsG: 42, fatG: 0.4)
        let off = FoodAnalysis.Item(name: "Rice", grams: 150, kcal: 400, proteinG: 4, carbsG: 42, fatG: 0.4)
        XCTAssertFalse(ok.kcalLooksInconsistent)
        XCTAssertTrue(off.kcalLooksInconsistent)
    }

    func testParsesEnvelopeAndReadsAnsweringModel() throws {
        let envelope: [String: Any] = [
            "model": "google/gemma-4-31b-it:free",
            "choices": [["message": ["role": "assistant", "content": clean]]],
        ]
        let result = try FoodAnalysis.parseResponse(JSONSerialization.data(withJSONObject: envelope))
        XCTAssertEqual(result.model, "google/gemma-4-31b-it:free")
        XCTAssertEqual(result.items.first?.kcal, 330)
    }

    func testPhotoRequestCarriesDataURLAndFallbackModels() throws {
        let models = OpenRouterClient.models(primary: "a/b:free")
        let body = try FoodAnalysis.requestBody(for: .photo(jpeg: Data([0xFF, 0xD8]), note: "no sauce"), models: models)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["models"] as? [String], ["a/b:free", "qwen/qwen3.8-27b:free", "openrouter/free"])
        let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
        let parts = try XCTUnwrap(messages[1]["content"] as? [[String: Any]])
        let imageURL = (parts.last?["image_url"] as? [String: String])?["url"]
        XCTAssertEqual(imageURL, "data:image/jpeg;base64,/9g=")
        XCTAssertTrue((parts.first?["text"] as? String)?.contains("no sauce") == true)
    }

    func testModelListDedupesAndCapsAtThree() {
        XCTAssertEqual(OpenRouterClient.models(primary: "openrouter/free"), ["openrouter/free", "qwen/qwen3.8-27b:free"])
        XCTAssertEqual(OpenRouterClient.models(primary: "x").count, 3)
    }

    func testPaidPrimaryFallsBackToFreeModelsWithCappedOutput() throws {
        let models = OpenRouterClient.models(primary: "anthropic/claude-sonnet-5")
        XCTAssertEqual(models, ["anthropic/claude-sonnet-5", "qwen/qwen3.8-27b:free", "openrouter/free"])
        let body = try FoodAnalysis.requestBody(for: .text("1 banana"), models: models)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["max_tokens"] as? Int, 2048)
    }

    func testStatusCodesMapToPlainErrors() {
        XCTAssertNil(OpenRouterClient.error(forStatus: 200))
        XCTAssertEqual(OpenRouterClient.error(forStatus: 401), .badKey)
        XCTAssertEqual(OpenRouterClient.error(forStatus: 402), .noCredits)
        XCTAssertEqual(OpenRouterClient.error(forStatus: 429), .rateLimited)
        XCTAssertEqual(OpenRouterClient.error(forStatus: 503), .server(503))
    }
}
