import Foundation

/// The app's only network client. It talks to OpenRouter with the user's own key, and only when
/// they ask for a food estimate — nothing else about them leaves the device.
enum OpenRouterClient {
    static let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    static let modelsEndpoint = URL(string: "https://openrouter.ai/api/v1/models")!
    static let defaultModel = "google/gemma-4-31b-it:free"
    // The router picks any currently free image-capable model, so a retired default still gets an answer.
    static let fallbackModels = ["qwen/qwen3.8-27b:free", "openrouter/free"]
    // Hand-picked: the live catalog has 100+ paid models, too many to offer in a picker.
    static let paidModels = ["openai/gpt-5.6-terra", "anthropic/claude-sonnet-5"]

    enum ClientError: LocalizedError, Equatable {
        case missingKey, badKey, noCredits, rateLimited, server(Int), offline, timedOut, unreadable

        var errorDescription: String? {
            switch self {
            case .missingKey: "Add your OpenRouter key in Fuel settings."
            case .badKey: "OpenRouter rejected the key. Check it in Fuel settings."
            case .noCredits: "This model needs credits on your OpenRouter account."
            case .rateLimited: "Free limit reached for now (50 a day without credits). Try later or log it manually."
            case let .server(code): "OpenRouter returned an error (\(code)). Try again or log it manually."
            case .offline: "You're offline. Log it manually or try again later."
            case .timedOut: "The model took too long. Try again or log it manually."
            case .unreadable: "Couldn't read the model's answer. Try again or log it manually."
            }
        }
    }

    static func models(primary: String) -> [String] {
        // OpenRouter caps the fallback list at three.
        Array(([primary] + fallbackModels).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }.prefix(3))
    }

    static func request(body: Data, key: String) -> URLRequest {
        var request = URLRequest(url: endpoint, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("LLR", forHTTPHeaderField: "X-Title")
        request.httpBody = body
        return request
    }

    static func error(forStatus status: Int) -> ClientError? {
        switch status {
        case 200..<300: nil
        case 401, 403: .badKey
        case 402: .noCredits
        case 429: .rateLimited
        default: .server(status)
        }
    }

    static func analyze(_ input: FoodAnalysis.Input, key: String, model: String) async throws -> FoodAnalysis.Result {
        guard !key.isEmpty else { throw ClientError.missingKey }
        let body = try FoodAnalysis.requestBody(for: input, models: models(primary: model))
        let data = try await send(request(body: body, key: key))
        do {
            return try FoodAnalysis.parseResponse(data)
        } catch {
            throw ClientError.unreadable
        }
    }

    /// Stage 1: names foods and guesses grams from a photo; no macros are requested.
    static func identify(jpeg: Data, note: String, key: String, model: String) async throws -> [FoodAnalysis.Ingredient] {
        guard !key.isEmpty else { throw ClientError.missingKey }
        let body = try FoodAnalysis.identifyRequestBody(jpeg: jpeg, note: note, models: models(primary: model))
        let data = try await send(request(body: body, key: key))
        do {
            return try FoodAnalysis.parseIdentify(data)
        } catch {
            throw ClientError.unreadable
        }
    }

    /// Stage 3: macros for a list the user has already corrected; text only, no image.
    static func analyze(_ ingredients: [FoodAnalysis.Ingredient], key: String, model: String) async throws -> FoodAnalysis.Result {
        try await analyze(FoodAnalysis.analysisInput(for: ingredients), key: key, model: model)
    }

    /// Free vision models that exist right now, from OpenRouter's public list; IDs come and go too
    /// often to hard-code more than a default.
    static func freeVisionModels() async throws -> [String] {
        struct List: Decodable {
            struct Model: Decodable {
                struct Arch: Decodable { let input_modalities: [String]?; let output_modalities: [String]? }
                let id: String
                let architecture: Arch?
            }
            let data: [Model]
        }
        let data = try await send(URLRequest(url: modelsEndpoint, timeoutInterval: 15))
        return try JSONDecoder().decode(List.self, from: data).data
            .filter { ($0.id.hasSuffix(":free") || $0.id == "openrouter/free")
                && ($0.architecture?.input_modalities ?? []).contains("image")
                && ($0.architecture?.output_modalities ?? ["text"]).contains("text") }
            .map(\.id)
            .sorted()
    }

    private static func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut: throw ClientError.timedOut
            case .notConnectedToInternet, .networkConnectionLost: throw ClientError.offline
            default: throw ClientError.server(error.errorCode)
            }
        }
        if let status = (response as? HTTPURLResponse)?.statusCode, let failure = error(forStatus: status) {
            throw failure
        }
        return data
    }
}
