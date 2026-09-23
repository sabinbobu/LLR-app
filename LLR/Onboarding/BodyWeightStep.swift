import SwiftUI

struct BodyWeightStep: View {
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @AppStorage(StorageKey.bodyWeightKg) private var weightKg: Double = 70
    let next: () -> Void

    /// Ruler works in integer tenths of the display unit so every tick is an exact, stable scroll id.
    private var tenths: Binding<Int> {
        Binding(
            get: { Int((unit.fromKg(weightKg) * 10).rounded()) },
            set: { weightKg = unit.toKg(Double($0) / 10) }
        )
    }

    private var range: ClosedRange<Int> { unit == .kg ? 200...3000 : 440...6600 }

    var body: some View {
        OnboardingScaffold(title: "What is your weight?", showsPrivacyNote: true, onContinue: next) {
            VStack(spacing: 48) {
                PillToggle(options: WeightUnit.allCases, selection: $unit) { $0 == .kg ? "Kilograms" : "Pounds" }
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(format: "%.1f", Double(tenths.wrappedValue) / 10))
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(unit.rawValue).font(.title2.bold())
                }
                WeightRuler(tenths: tenths, range: range)
                    .id(unit)
                Spacer(minLength: 0)
            }
        }
    }
}
