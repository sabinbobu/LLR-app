import SwiftUI

/// Manual entry and editing of a single saved item.
struct FoodEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let entry: FoodEntry?
    private let onSaved: () -> Void

    @State private var name: String
    @State private var when: Date
    @State private var meal: Meal
    @State private var grams: Double
    @State private var kcal: Double
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double

    init(entry: FoodEntry) {
        self.entry = entry
        self.onSaved = {}
        _when = State(initialValue: entry.loggedAt)
        _name = State(initialValue: entry.name)
        _meal = State(initialValue: entry.meal)
        _grams = State(initialValue: entry.grams ?? 0)
        _kcal = State(initialValue: entry.kcal)
        _protein = State(initialValue: entry.proteinG)
        _carbs = State(initialValue: entry.carbsG)
        _fat = State(initialValue: entry.fatG)
    }

    init(newAt loggedAt: Date, onSaved: @escaping () -> Void) {
        self.entry = nil
        self.onSaved = onSaved
        _when = State(initialValue: loggedAt)
        _name = State(initialValue: "")
        _meal = State(initialValue: Meal.suggested(for: loggedAt))
        _grams = State(initialValue: 0)
        _kcal = State(initialValue: 0)
        _protein = State(initialValue: 0)
        _carbs = State(initialValue: 0)
        _fat = State(initialValue: 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Food name", text: $name)
                    Picker("Meal", selection: $meal) {
                        ForEach(Meal.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                }
                Section {
                    // Past dates are allowed so a forgotten meal can be added, or a wrong day fixed.
                    DatePicker("When", selection: $when, in: ...Date.now)
                }
                Section {
                    numberRow("Portion (g)", $grams)
                    numberRow("Calories", $kcal)
                    numberRow("Protein (g)", $protein)
                    numberRow("Carbs (g)", $carbs)
                    numberRow("Fat (g)", $fat)
                } footer: {
                    if kcal == 0, protein + carbs + fat > 0 {
                        Button("Fill calories from macros (\(Int(protein * 4 + carbs * 4 + fat * 9)) kcal)") {
                            kcal = (protein * 4 + carbs * 4 + fat * 9).rounded()
                        }
                        .font(.footnote)
                    }
                }
                if let entry, let model = entry.aiModel {
                    Section { LabeledContent("Estimated by", value: model).font(.footnote) }
                }
            }
            .navigationTitle(entry == nil ? "Add Food" : "Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func numberRow(_ title: String, _ value: Binding<Double>) -> some View {
        LabeledContent(title) {
            TextField(title, value: value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let entry {
            entry.name = trimmed
            entry.loggedAt = FoodLogTime.clamped(when)
            entry.meal = meal
            entry.grams = grams > 0 ? grams : nil
            entry.kcal = kcal
            entry.proteinG = protein
            entry.carbsG = carbs
            entry.fatG = fat
        } else {
            context.insert(FoodEntry(name: trimmed, meal: meal, kcal: kcal, proteinG: protein, carbsG: carbs,
                                     fatG: fat, grams: grams > 0 ? grams : nil, loggedAt: FoodLogTime.clamped(when)))
        }
        dismiss()
        onSaved()
    }
}
