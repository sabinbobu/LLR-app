import Foundation

/// Stage 1 and 3 of the two-step flow: the vision model only names foods and guesses grams, the user
/// fixes that list, and only then are macros asked for, from text.
extension FoodAnalysis {
    struct Ingredient: Identifiable, Hashable {
        let id = UUID()
        var name: String
        var grams: Double

        var isValid: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && grams.isFinite && grams > 0
        }
    }

    static let identifyPrompt = """
    You identify foods in a photo of a meal. List each distinct food and estimate its portion in grams \
    from visual cues such as plate size. Do not give calories or macronutrients. \
    Reply with ONLY this JSON, no prose:
    {"ingredients":[{"name":"string","grams":number}]}
    """

    static func canAnalyze(_ ingredients: [Ingredient]) -> Bool {
        !ingredients.isEmpty && ingredients.allSatisfy(\.isValid)
    }

    static func identifyRequestBody(jpeg: Data, note: String, models: [String]) throws -> Data {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let content: [[String: Any]] = [
            ["type": "text", "text": trimmed.isEmpty ? "List the foods in this meal." : "List the foods in this meal. Note: \(trimmed)"],
            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(jpeg.base64EncodedString())"]],
        ]
        let body: [String: Any] = [
            "models": models,
            "messages": [
                ["role": "system", "content": identifyPrompt],
                ["role": "user", "content": content],
            ],
            "temperature": 0.2,
            "max_tokens": 2048,
        ]
        return try JSONSerialization.data(withJSONObject: body)
    }

    /// The corrected list as text with quantities stated as fact, so the model does composition
    /// arithmetic instead of re-guessing portions. No image is attached.
    static func analysisInput(for ingredients: [Ingredient]) -> Input {
        let list = ingredients.map { "\(Int($0.grams.rounded())) g \($0.name.trimmingCharacters(in: .whitespacesAndNewlines))" }
        return .text(list.joined(separator: ", ") + ". These quantities are exact; do not change them.")
    }

    static func parseIdentify(_ data: Data) throws -> [Ingredient] {
        try parseIdentifyContent(messageContent(data).content)
    }

    static func parseIdentifyContent(_ content: String) throws -> [Ingredient] {
        guard let start = content.firstIndex(of: "{"), let end = content.lastIndex(of: "}"), start < end else {
            throw ParseError.noJSON
        }
        struct Payload: Decodable {
            struct Raw: Decodable { let name: String; let grams: Double }
            let ingredients: [Raw]
        }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: Data(content[start...end].utf8)) else {
            throw ParseError.noJSON
        }
        guard !payload.ingredients.isEmpty else { throw ParseError.noItems }
        return try payload.ingredients.map { raw in
            guard raw.grams.isFinite, raw.grams >= 0, raw.grams <= InputLimits.maxAmount else { throw ParseError.invalidValue(raw.name) }
            return Ingredient(name: raw.name, grams: raw.grams)
        }
    }
}
