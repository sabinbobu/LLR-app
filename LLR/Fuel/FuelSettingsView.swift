import SwiftData
import SwiftUI

struct FuelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<BodyMeasurement> { $0.kindRaw == "bodyWeight" }, sort: \BodyMeasurement.takenAt, order: .reverse)
    private var weights: [BodyMeasurement]
    @AppStorage(StorageKey.fuelModel) private var model = OpenRouterClient.defaultModel
    @AppStorage(StorageKey.fuelActivity) private var activityRaw = ActivityLevel.moderate.rawValue
    @AppStorage(StorageKey.fuelKcalOverride) private var kcalOverride = 0.0
    @AppStorage(StorageKey.fuelProteinOverride) private var proteinOverride = 0.0
    @AppStorage(StorageKey.fuelCarbsOverride) private var carbsOverride = 0.0
    @AppStorage(StorageKey.fuelFatOverride) private var fatOverride = 0.0

    @State private var key = KeychainStore.get(StorageKey.openRouterKey) ?? ""
    @State private var availableModels: [String] = []
    @State private var keyStatus: String?
    @State private var testing = false

    private var auto: Macros {
        NutritionTargets.auto(NutritionTargets.profile(latestWeightKg: weights.first?.value))
    }

    var body: some View {
        NavigationStack {
            Form {
                keySection
                Section {
                    Picker("Model", selection: $model) {
                        ForEach(modelChoices, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("AI model")
                } footer: {
                    Text("Free vision models on OpenRouter right now. If one is retired, requests fall back to another free model automatically.")
                }
                Section {
                    Picker("Activity", selection: $activityRaw) {
                        ForEach(ActivityLevel.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    overrideRow("Calories", unit: "kcal", auto: auto.kcal, value: $kcalOverride)
                    overrideRow("Protein", unit: "g", auto: auto.proteinG, value: $proteinOverride)
                    overrideRow("Carbs", unit: "g", auto: auto.carbsG, value: $carbsOverride)
                    overrideRow("Fat", unit: "g", auto: auto.fatG, value: $fatOverride)
                    Button("Reset to auto") {
                        kcalOverride = 0; proteinOverride = 0; carbsOverride = 0; fatOverride = 0
                    }
                } header: {
                    Text("Daily targets")
                } footer: {
                    Text("""
                    Auto targets use your profile and latest bodyweight: Mifflin-St Jeor energy × activity, \
                    adjusted for your goal; protein 1.6 g/kg (Morton et al. 2018); fat 25% of calories; carbs \
                    the rest. Leave a field empty to use the auto value.
                    """)
                }
            }
            .navigationTitle("Fuel Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() }.bold() }
            .task { availableModels = (try? await OpenRouterClient.freeVisionModels()) ?? [] }
        }
    }

    /// The saved model stays selectable even if it has dropped off the live list or the list failed to load.
    private var modelChoices: [String] {
        Array(Set(availableModels + [model, OpenRouterClient.defaultModel])).sorted()
    }

    private var keySection: some View {
        Section {
            SecureField("sk-or-…", text: $key)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: key) { _, value in
                    KeychainStore.set(value.trimmingCharacters(in: .whitespacesAndNewlines), for: StorageKey.openRouterKey)
                    keyStatus = nil
                }
            Button(testing ? "Testing…" : "Test key", action: testKey)
                .disabled(key.isEmpty || testing)
            if let keyStatus {
                Text(keyStatus).font(.footnote).foregroundStyle(.secondary)
            }
        } header: {
            Text("OpenRouter key")
        } footer: {
            Text("Stored in the iOS Keychain on this device only. Only a food photo or description you choose to analyze is sent to OpenRouter. Free keys allow 50 estimates a day.")
        }
    }

    private func overrideRow(_ title: String, unit: String, auto: Double, value: Binding<Double>) -> some View {
        LabeledContent(title) {
            TextField("\(Int(auto)) \(unit)", value: Binding(get: { value.wrappedValue > 0 ? value.wrappedValue : nil },
                                                               set: { value.wrappedValue = $0 ?? 0 }),
                      format: .number.precision(.fractionLength(0)))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
    }

    private func testKey() {
        testing = true
        Task {
            defer { testing = false }
            do {
                _ = try await OpenRouterClient.analyze(.text("1 medium banana"), key: key, model: model)
                keyStatus = "Key works."
            } catch {
                keyStatus = error.localizedDescription
            }
        }
    }
}
