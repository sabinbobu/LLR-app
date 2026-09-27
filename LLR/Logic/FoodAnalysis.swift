import Foundation

/// Turns a photo or a description into draft food items. Everything here is pure (request in,
/// `Data` out) so it can be tested without the network; `OpenRouterClient` does the sending.
enum FoodAnalysis {
    enum Input {
        case photo(jpeg: Data, note: String)
        case text(String)
    }

    enum Confidence: String, Decodable {
        case low, medium, high
    }

    struct Item: Equatable, Identifiable {
        let id = UUID()
        var name: String
        var grams: Double?
        var kcal: Double
        var proteinG: Double
        var carbsG: Double
        var fatG: Double

        /// Models often get the macros roughly right and the total wrong (or vice versa); a gap
        /// this big against 4/4/9 kcal per gram means at least one number needs a human look.
        var kcalLooksInconsistent: Bool {
            let fromMacros = proteinG * 4 + carbsG * 4 + fatG * 9
            guard max(kcal, fromMacros) > 20 else { return false }
            return abs(kcal - fromMacros) / max(kcal, fromMacros) > 0.25
        }

        static func == (a: Item, b: Item) -> Bool {
            a.name == b.name && a.grams == b.grams && a.kcal == b.kcal
                && a.proteinG == b.proteinG && a.carbsG == b.carbsG && a.fatG == b.fatG
        }
    }

    struct Result {
        var items: [Item]
        var confidence: Confidence?
        var model: String?
    }

    enum ParseError: Error, Equatable {
        case noJSON, noItems, invalidValue(String)
    }

    static let systemPrompt = """
    You are a nutrition estimator. Identify each distinct food in the user's meal and estimate its \
    portion in grams and its macronutrients. Use standard food-composition values (e.g. USDA). \
    If a portion is stated, use it; otherwise estimate from visual cues such as plate size. \
    Reply with ONLY this JSON, no prose:
    {"items":[{"name":"string","grams":number,"kcal":number,"protein_g":number,"carbs_g":number,"fat_g":number}],"confidence":"low|medium|high"}
    """

    static func requestBody(for input: Input, models: [String]) throws -> Data {
        let userContent: [[String: Any]]
        switch input {
        case let .photo(jpeg, note):
            var parts: [[String: Any]] = [[
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(jpeg.base64EncodedString())"],
            ]]
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            parts.insert(["type": "text", "text": trimmed.isEmpty ? "Estimate this meal." : "Estimate this meal. Note: \(trimmed)"], at: 0)
            userContent = parts
        case let .text(description):
            userContent = [["type": "text", "text": "Estimate this meal: \(description)"]]
        }
        let body: [String: Any] = [
            "models": models,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent],
            ],
            // Low temperature: the same plate should not give a different answer on every retry.
            "temperature": 0.2,
        ]
        return try JSONSerialization.data(withJSONObject: body)
    }

    /// Parses an OpenRouter chat-completions response body.
    static func parseResponse(_ data: Data) throws -> Result {
        struct Envelope: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String? }
                let message: Message
            }
            let model: String?
            let choices: [Choice]
        }
        let envelope = try JSONDecoder().decode(Envelope.self, from: data)
        guard let content = envelope.choices.first?.message.content else { throw ParseError.noJSON }
        var result = try parseContent(content)
        result.model = envelope.model
        return result
    }

    /// Free models ignore "JSON only" often enough that the payload arrives fenced or wrapped in
    /// prose; take the outermost object rather than trusting the whole string.
    static func parseContent(_ content: String) throws -> Result {
        guard let start = content.firstIndex(of: "{"), let end = content.lastIndex(of: "}"), start < end else {
            throw ParseError.noJSON
        }
        struct Payload: Decodable {
            struct RawItem: Decodable {
                let name: String
                let grams: Double?
                let kcal: Double
                let protein_g: Double
                let carbs_g: Double
                let fat_g: Double
            }
            let items: [RawItem]
            let confidence: String?
        }
        let json = Data(content[start...end].utf8)
        guard let payload = try? JSONDecoder().decode(Payload.self, from: json) else { throw ParseError.noJSON }
        guard !payload.items.isEmpty else { throw ParseError.noItems }
        let items = try payload.items.map { raw -> Item in
            for value in [raw.kcal, raw.protein_g, raw.carbs_g, raw.fat_g, raw.grams ?? 0] where !value.isFinite || value < 0 {
                throw ParseError.invalidValue(raw.name)
            }
            return Item(name: raw.name, grams: raw.grams, kcal: raw.kcal.rounded(),
                        proteinG: raw.protein_g, carbsG: raw.carbs_g, fatG: raw.fat_g)
        }
        return Result(items: items, confidence: payload.confidence.flatMap { Confidence(rawValue: $0.lowercased()) }, model: nil)
    }
}
