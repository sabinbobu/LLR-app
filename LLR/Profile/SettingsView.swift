import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @AppStorage(StorageKey.restSeconds) private var restSeconds = 90
    @AppStorage(StorageKey.barKg) private var barKg = PlateCalculator.defaultBar(for: .kg)
    @AppStorage(StorageKey.barLbs) private var barLbs = PlateCalculator.defaultBar(for: .lbs)

    private var bar: Binding<Double> { unit == .kg ? $barKg : $barLbs }

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Weight", selection: $unit) {
                        ForEach(WeightUnit.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Rest Timer") {
                    Stepper(value: $restSeconds, in: 15...600, step: 15) {
                        LabeledContent("Default rest", value: Format.clock(TimeInterval(restSeconds)))
                    }
                }
                Section("Plate Calculator") {
                    Stepper(value: bar, in: 0...60, step: unit == .kg ? 2.5 : 5) {
                        LabeledContent("Bar weight", value: "\(unit.format(kg: unit.toKg(bar.wrappedValue))) \(unit.rawValue)")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}
