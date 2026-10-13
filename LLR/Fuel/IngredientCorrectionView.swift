import SwiftUI

/// What the vision model saw, editable before any macros exist. Nothing is saved from here.
struct IdentifiedMeal: Identifiable, Hashable {
    let id = UUID()
    var ingredients: [FoodAnalysis.Ingredient]
    var photoData: Data?
}

struct IngredientCorrectionView: View {
    @AppStorage(StorageKey.fuelModel) private var model = OpenRouterClient.defaultModel
    let loggedAt: Date
    let photoData: Data?
    let onSaved: () -> Void

    @State private var ingredients: [FoodAnalysis.Ingredient]
    @State private var analyzing = false
    @State private var errorMessage: String?
    @State private var review: FoodAnalysis.Result?
    @State private var manual = false

    init(meal: IdentifiedMeal, loggedAt: Date, onSaved: @escaping () -> Void) {
        _ingredients = State(initialValue: meal.ingredients)
        photoData = meal.photoData
        self.loggedAt = loggedAt
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section {
                Label("Check what the AI saw. Fix names and grams, then analyse.", systemImage: "list.bullet.clipboard")
                    .font(.subheadline)
            }
            Section("Ingredients") {
                ForEach($ingredients) { $item in
                    HStack {
                        TextField("Name", text: $item.name)
                        TextField("g", value: $item.grams, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("g").foregroundStyle(.secondary)
                    }
                }
                .onDelete { ingredients.remove(atOffsets: $0) }
                Button("Add ingredient", systemImage: "plus") {
                    ingredients.append(.init(name: "", grams: 100))
                }
            }
            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Theme.over)
                    Button("Enter manually instead") { manual = true }
                }
            }
            Section {
                Button(action: analyze) {
                    if analyzing { HStack { ProgressView(); Text("Analysing…") } }
                    else { Label("Analyse", systemImage: "sparkles") }
                }
                .disabled(analyzing || !FoodAnalysis.canAnalyze(ingredients))
                if !FoodAnalysis.canAnalyze(ingredients) {
                    Text("Every ingredient needs a name and grams above zero.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Ingredients")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $review) { result in
            FoodReviewView(result: result, photoData: photoData, loggedAt: loggedAt, onSaved: onSaved)
        }
        .sheet(isPresented: $manual) { FoodEditView(newAt: loggedAt, onSaved: onSaved) }
    }

    private func analyze() {
        errorMessage = nil
        analyzing = true
        let key = KeychainStore.get(StorageKey.openRouterKey) ?? ""
        let list = ingredients
        Task {
            defer { analyzing = false }
            do {
                review = try await OpenRouterClient.analyze(list, key: key, model: model)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
