import SwiftUI

struct PlateCalculatorView: View {
    let unit: WeightUnit
    @State private var target: Double
    @AppStorage(StorageKey.barKg) private var barKg = PlateCalculator.defaultBar(for: .kg)
    @AppStorage(StorageKey.barLbs) private var barLbs = PlateCalculator.defaultBar(for: .lbs)
    @Environment(\.dismiss) private var dismiss

    init(unit: WeightUnit, targetKg: Double) {
        self.unit = unit
        _target = State(initialValue: (unit.fromKg(targetKg) * 10).rounded() / 10)
    }

    private var bar: Double { unit == .kg ? barKg : barLbs }
    private var result: PlateCalculator.Result {
        PlateCalculator.load(target: target, bar: bar, plates: PlateCalculator.plates(for: unit))
    }
    private var step: Double { unit == .kg ? 2.5 : 5 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Stepper(value: $target, in: 0...1000, step: step) {
                    Text("\(format(target)) \(unit.rawValue)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                BarbellDiagram(perSide: result.perSide, unit: unit)
                    .frame(height: 140)
                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Bar", value: "\(format(bar)) \(unit.rawValue)")
                    LabeledContent("Each side", value: perSideSummary)
                    if result.remainder > 0.001 {
                        Label("Closest loadable: \(format(result.loaded)) \(unit.rawValue)", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
                Spacer()
            }
            .padding()
            .animation(.snappy, value: target)
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var perSideSummary: String {
        guard !result.perSide.isEmpty else { return "Empty bar" }
        let counts = Dictionary(grouping: result.perSide, by: { $0 }).mapValues(\.count)
        return counts.keys.sorted(by: >).map { "\(format($0)) × \(counts[$0]!)" }.joined(separator: ", ")
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%g", value)
    }
}
