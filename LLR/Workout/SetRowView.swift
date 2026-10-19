import SwiftUI

/// Empty fields show the pre-filled value as a grey placeholder; the model already holds that
/// value, so tapping the check alone logs the set — the one-tap path the whole app is built around.
struct SetRowView: View {
    let entry: SetEntry
    let label: String
    let unit: WeightUnit
    var effortScale: EffortScale = .off
    let isStriped: Bool
    let isRecord: Bool
    let onToggle: () -> Bool

    @State private var weightText = ""
    @State private var repsText = ""
    @State private var rejectCount = 0

    private var isDone: Bool { entry.completedAt != nil }

    var body: some View {
        HStack {
            Menu {
                Picker("Set type", selection: kindBinding) {
                    ForEach(SetKind.allCases) { Text($0.title).tag($0) }
                }
            } label: {
                Text(label)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Self.color(for: entry.kind))
                    .frame(width: 56, height: 52)
                    .overlay(alignment: .topTrailing) {
                        if isRecord {
                            Image(systemName: "trophy.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                                .padding(6)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .contentShape(Rectangle())
            }
            .animation(.bouncy, value: isRecord)
            TextField(entry.weightKg > 0 ? unit.format(kg: entry.weightKg) : "-", text: $weightText)
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity)
            TextField(entry.reps > 0 ? "\(entry.reps)" : "-", text: $repsText)
                .keyboardType(.numberPad)
                .frame(maxWidth: .infinity)
            if effortScale != .off {
                EffortChip(rir: Binding(get: { entry.rir }, set: { entry.rir = $0 }), scale: effortScale)
            }
            Button {
                if onToggle() {
                    if isDone { fillTextFromModel() }
                } else {
                    rejectCount += 1
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.body.bold())
                    .foregroundStyle(isDone ? Color.white : Color.secondary)
                    .frame(width: 36, height: 36)
                    .background(isDone ? Theme.completedCheck : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                    .frame(width: 64, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // The checkmark symbol's own label is "Selected", which VoiceOver read out on unticked sets too.
            .accessibilityLabel(isDone ? "Mark set not done" : "Complete set")
            .accessibilityValue(isDone ? "Done" : "Not done")
            .accessibilityIdentifier("set-check")
            .accessibilityRemoveTraits(.isSelected)
        }
        .font(.title3)
        .multilineTextAlignment(.center)
        .monospacedDigit()
        .frame(height: 52)
        .background(isDone ? Theme.completedRow : (isStriped ? Theme.card : Color.clear))
        .sensoryFeedback(.impact(weight: .medium), trigger: isDone)
        .sensoryFeedback(.error, trigger: rejectCount)
        .sensoryFeedback(.success, trigger: isRecord) { _, new in new }
        .onAppear { if isDone { fillTextFromModel() } }
        .onChange(of: weightText) { _, text in
            if let value = WeightUnit.parse(text) { entry.weightKg = unit.toKg(value) }
        }
        .onChange(of: repsText) { _, text in
            if let value = Int(text) { entry.reps = value }
        }
    }

    private var kindBinding: Binding<SetKind> {
        Binding(get: { entry.kind }, set: { entry.kind = $0 })
    }

    static func color(for kind: SetKind) -> Color {
        switch kind {
        case .normal: .primary
        case .warmup: .orange
        case .drop: .purple
        case .failure: .red
        }
    }

    private func fillTextFromModel() {
        if weightText.isEmpty { weightText = unit.format(kg: entry.weightKg) }
        if repsText.isEmpty { repsText = "\(entry.reps)" }
    }
}
