import SwiftUI

/// Empty fields show the pre-filled value as a grey placeholder; the model already holds that
/// value, so tapping the check alone logs the set — the one-tap path the whole app is built around.
struct SetRowView: View {
    let entry: SetEntry
    let number: Int
    let unit: WeightUnit
    let isStriped: Bool
    let onToggle: () -> Bool

    @State private var weightText = ""
    @State private var repsText = ""
    @State private var rejectCount = 0

    private var isDone: Bool { entry.completedAt != nil }

    var body: some View {
        HStack {
            Text("\(number)")
                .font(.title3.weight(.medium))
                .frame(width: 56)
            TextField(entry.weightKg > 0 ? unit.format(kg: entry.weightKg) : "-", text: $weightText)
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity)
            TextField(entry.reps > 0 ? "\(entry.reps)" : "-", text: $repsText)
                .keyboardType(.numberPad)
                .frame(maxWidth: .infinity)
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
        }
        .font(.title3)
        .multilineTextAlignment(.center)
        .monospacedDigit()
        .frame(height: 52)
        .background(isDone ? Theme.completedRow : (isStriped ? Theme.card : Color.clear))
        .sensoryFeedback(.impact(weight: .medium), trigger: isDone)
        .sensoryFeedback(.error, trigger: rejectCount)
        .onAppear { if isDone { fillTextFromModel() } }
        .onChange(of: weightText) { _, text in
            if let value = WeightUnit.parse(text) { entry.weightKg = unit.toKg(value) }
        }
        .onChange(of: repsText) { _, text in
            if let value = Int(text) { entry.reps = value }
        }
    }

    private func fillTextFromModel() {
        if weightText.isEmpty { weightText = unit.format(kg: entry.weightKg) }
        if repsText.isEmpty { repsText = "\(entry.reps)" }
    }
}
