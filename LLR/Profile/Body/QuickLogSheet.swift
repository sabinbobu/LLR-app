import SwiftData
import SwiftUI

/// Pre-filled with the last value, so the common case (a weigh-in within a few hundred grams of
/// yesterday) is open → nudge → Save, never typing from an empty field.
struct QuickLogSheet: View {
    let kind: MeasurementKind
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @AppStorage(StorageKey.heightCm) private var profileHeightCm = 170
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double
    @State private var date = Date.now
    @State private var saved = false

    init(kind: MeasurementKind, latestCanonical: Double?) {
        self.kind = kind
        let unit = WeightUnit.stored
        let fallback: Double = switch kind.dimension {
        case .mass: 70
        case .length: kind == .height ? 170 : 35
        case .percent: 18
        }
        _value = State(initialValue: Self.display(latestCanonical ?? fallback, kind: kind, unit: unit))
    }

    private var step: Double { kind.dimension == .percent ? 0.5 : 0.1 }

    private var suffix: String {
        switch kind.dimension {
        case .mass: unit.rawValue
        case .length: unit.lengthSuffix
        case .percent: "%"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                HStack(spacing: 20) {
                    stepButton("minus") { value = max(0, value - step) }
                    VStack(spacing: 0) {
                        TextField("", value: $value, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText(value: value))
                        Text(suffix).font(.title3).foregroundStyle(.secondary)
                    }
                    stepButton("plus") { value += step }
                }
                DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                    .padding(.horizontal)
                Button("Save", action: save)
                    .buttonStyle(SheetButtonStyle())
                    .disabled(value <= 0)
                    .padding(.horizontal)
            }
            .padding(.top, 12)
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
        .presentationDetents([.height(340)])
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
                .background(Theme.accentSoft, in: Circle())
                .foregroundStyle(Theme.accent)
        }
        .buttonRepeatBehavior(.enabled)
        .sensoryFeedback(.selection, trigger: value)
    }

    private func save() {
        let canonical: Double = switch kind.dimension {
        case .mass: unit.toKg(value)
        case .length: unit.toCm(value)
        case .percent: value
        }
        context.insert(BodyMeasurement(kind: kind, value: canonical, takenAt: date))
        // Fuel's targets read the profile height; keep it in step with the measurement history.
        if kind == .height { profileHeightCm = Int(canonical.rounded()) }
        saved = true
        dismiss()
    }

    static func display(_ canonical: Double, kind: MeasurementKind, unit: WeightUnit) -> Double {
        let raw: Double = switch kind.dimension {
        case .mass: unit.fromKg(canonical)
        case .length: unit.fromCm(canonical)
        case .percent: canonical
        }
        return (raw * 10).rounded() / 10
    }
}
