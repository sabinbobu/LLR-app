import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @AppStorage(StorageKey.restSeconds) private var restSeconds = 90
    @AppStorage(StorageKey.effortScale) private var effortScale: EffortScale = .off
    @AppStorage(StorageKey.oneRepMaxFormula) private var formula: OneRepMax.Formula = .epley
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
                Section {
                    Picker("Rate each set", selection: $effortScale) {
                        ForEach(EffortScale.allCases) { Text($0.title).tag($0) }
                    }
                } header: {
                    Text("Effort")
                } footer: {
                    Text("Adds an optional column to each set. RIR is reps in reserve: how many more you could have done. RPE is the same rating on a 10-point scale, so RPE 8 is 2 in reserve.")
                }
                Section {
                    Picker("Formula", selection: $formula) {
                        ForEach(OneRepMax.Formula.allCases) { Text($0.title).tag($0) }
                    }
                } header: {
                    Text("Estimated One Rep Max")
                } footer: {
                    Text("Used for records, progress charts and Structural Balance. Sets above \(OneRepMax.repCap) reps get no estimate: past that the formulas disagree too much to trust.")
                }
                Section("Plate Calculator") {
                    Stepper(value: bar, in: 0...60, step: unit == .kg ? 2.5 : 5) {
                        LabeledContent("Bar weight", value: "\(unit.format(kg: unit.toKg(bar.wrappedValue))) \(unit.rawValue)")
                    }
                }
                Section("Data") {
                    NavigationLink {
                        DataTransferView()
                    } label: {
                        Label("Import & Export", systemImage: "arrow.up.arrow.down")
                    }
                }
                Section("About") {
                    NavigationLink {
                        AcknowledgementsView()
                    } label: {
                        Label("Acknowledgements", systemImage: "info.circle")
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
