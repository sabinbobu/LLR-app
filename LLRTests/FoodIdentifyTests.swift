import XCTest
@testable import LLR

final class FoodIdentifyTests: XCTestCase {
    func testParsesFencedIdentifyJSON() throws {
        let content = "Sure!\n```json\n{\"ingredients\":[{\"name\":\"Rice\",\"grams\":180},{\"name\":\"Chicken\",\"grams\":120.5}]}\n```"
        let list = try FoodAnalysis.parseIdentifyContent(content)
        XCTAssertEqual(list.map(\.name), ["Rice", "Chicken"])
        XCTAssertEqual(list.map(\.grams), [180, 120.5])
    }

    func testGarbledOrEmptyIdentifyThrows() {
        XCTAssertThrowsError(try FoodAnalysis.parseIdentifyContent("no food here")) {
            XCTAssertEqual($0 as? FoodAnalysis.ParseError, .noJSON)
        }
        XCTAssertThrowsError(try FoodAnalysis.parseIdentifyContent(#"{"ingredients":[]}"#)) {
            XCTAssertEqual($0 as? FoodAnalysis.ParseError, .noItems)
        }
        XCTAssertThrowsError(try FoodAnalysis.parseIdentifyContent(#"{"ingredients":[{"name":"x","grams":-3}]}"#))
    }

    func testCorrectedListBecomesATextRequestWithoutAnyImage() throws {
        let list = [FoodAnalysis.Ingredient(name: "Brown rice", grams: 150), FoodAnalysis.Ingredient(name: "Tofu", grams: 90)]
        let body = try FoodAnalysis.requestBody(for: FoodAnalysis.analysisInput(for: list), models: ["m"])
        let text = String(decoding: body, as: UTF8.self)
        XCTAssertTrue(text.contains("150 g Brown rice"))
        XCTAssertTrue(text.contains("90 g Tofu"))
        XCTAssertFalse(text.contains("image_url"))
        XCTAssertFalse(text.contains("base64"))
    }

    func testIdentifyRequestAsksForNoMacros() throws {
        let body = try FoodAnalysis.identifyRequestBody(jpeg: Data([1, 2, 3]), note: "", models: ["m"])
        let text = String(decoding: body, as: UTF8.self)
        XCTAssertTrue(text.contains("image_url"))
        XCTAssertFalse(text.contains("protein_g"))
    }

    func testAnalyseNeedsNamesAndPositiveGrams() {
        typealias I = FoodAnalysis.Ingredient
        XCTAssertFalse(FoodAnalysis.canAnalyze([]))
        XCTAssertFalse(FoodAnalysis.canAnalyze([I(name: "Rice", grams: 0)]))
        XCTAssertFalse(FoodAnalysis.canAnalyze([I(name: "  ", grams: 50)]))
        XCTAssertFalse(FoodAnalysis.canAnalyze([I(name: "Rice", grams: -5)]))
        XCTAssertTrue(FoodAnalysis.canAnalyze([I(name: "Rice", grams: 50)]))
    }
}
