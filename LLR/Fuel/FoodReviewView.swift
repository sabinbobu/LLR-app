import SwiftUI

/// Nothing the model says is saved until the user has seen it here: photo estimates are off by a
/// third on calories even for frontier models (Fridolfsson et al. 2025, Curr Dev Nutr).
struct FoodReviewView: View {
    @Environment(\.modelContext) private var context
    let photoData: Data?
    let loggedAt: Date
    let aiModel: String?
    let confidence: FoodAnalysis.Confidence?
    let onSaved: () -> Void

    @State private var items: [FoodAnalysis.Item]
    @State private var meal: Meal

    init(result: FoodAnalysis.Result, photoData: Data?, loggedAt: Date, onSaved: @escaping () -> Void) {
        self.photoData = photoData
        self.loggedAt = loggedAt
        self.aiModel = result.model
        self.confidence = result.confidence
        self.onSaved = onSaved
        _items = State(initialValue: result.items)
        _meal = State(initialValue: Meal.suggested(for: loggedAt))
    }

    private var total: Macros {
        items.reduce(.zero) { $0 + Macros(kcal: $1.kcal, proteinG: $1.proteinG, carbsG: $1.carbsG, fatG: $1.fatG) }
    }

    var body: some View {
        Form {
            Section {
                Label("AI estimate: check the portions before saving.", systemImage: "sparkles")
                    .font(.subheadline)
                if let confidence {
                    LabeledContent("Model confidence", value: confidence.rawValue.capitalized)
                }
                if let aiModel {
                    LabeledContent("Model", value: aiModel).font(.footnote)
                }
            }
            Section {
                Picker("Meal", selection: $meal) {
                    ForEach(Meal.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                }
                LabeledContent("Total", value: "\(Int(total.kcal)) kcal · P \(Int(total.proteinG)) · C \(Int(total.carbsG)) · F \(Int(total.fatG))")
                    .font(.subheadline.monospacedDigit())
            }
            ForEach($items) { $item in
                Section {
                    TextField("Name", text: $item.name).font(.headline)
                    numberRow("Portion (g)", value: Binding(get: { item.grams ?? 0 }, set: { item.grams = $0 > 0 ? $0 : nil }))
                    numberRow("Calories", value: $item.kcal)
                    numberRow("Protein (g)", value: $item.proteinG)
                    numberRow("Carbs (g)", value: $item.carbsG)
                    numberRow("Fat (g)", value: $item.fatG)
                    if item.kcalLooksInconsistent {
                        Label("Calories don't match the macros (4/4/9 kcal per gram). Check the numbers.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                } footer: {
                    Button("Remove", role: .destructive) { items.removeAll { $0.id == item.id } }
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Save", action: save).bold().disabled(items.isEmpty)
        }
    }

    private func numberRow(_ title: String, value: Binding<Double>) -> some View {
        LabeledContent(title) {
            TextField(title, value: value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
    }

    private func save() {
        for (index, item) in items.enumerated() {
            // The photo shows the whole plate; attach it once rather than duplicating the blob per item.
            context.insert(FoodEntry(
                name: item.name, meal: meal, kcal: item.kcal, proteinG: item.proteinG, carbsG: item.carbsG,
                fatG: item.fatG, grams: item.grams, source: .ai, aiModel: aiModel,
                photoData: index == 0 ? photoData : nil, loggedAt: loggedAt
            ))
        }
        onSaved()
    }
}
