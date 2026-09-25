import SwiftUI

/// A planning row, not a logging row: no checkmark, and an empty field is a deliberate "blank"
/// rather than zero — `SetRowView` conflates "not logged yet" with completion, which doesn't apply here.
struct RoutineSetRowView: View {
    let plan: RoutineSetPlan
    let label: String
    let unit: WeightUnit
    let isDurationBased: Bool
    let canRemove: Bool
    let onRemove: () -> Void

    @State private var weightText = ""
    @State private var repsText = ""
    @State private var secondsText = ""
    @FocusState private var focus: Field?

    private enum Field { case weight, reps, seconds }

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                Picker("Set type", selection: kindBinding) {
                    ForEach(SetKind.allCases) { Text($0.title).tag($0) }
                }
            } label: {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SetRowView.color(for: plan.kind))
                    .frame(width: 40, height: 32)
                    .background(Theme.field, in: RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityLabel("Set \(label), \(plan.kind.title)")

            if isDurationBased {
                input(text: $repsText, keyboard: .numberPad, field: .reps)
                    .accessibilityLabel("Set \(label) reps")
                input(text: $secondsText, keyboard: .numberPad, field: .seconds)
                    .accessibilityLabel("Set \(label) hold seconds")
            } else {
                input(text: $weightText, keyboard: .decimalPad, field: .weight)
                    .accessibilityLabel("Set \(label) weight in \(unit.rawValue)")
                input(text: $repsText, keyboard: .numberPad, field: .reps)
                    .accessibilityLabel("Set \(label) reps")
            }

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(.systemGray))
            .disabled(!canRemove)
            .opacity(canRemove ? 1 : 0.3)
            .accessibilityLabel("Remove set \(label)")
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 5)
        .onAppear {
            weightText = plan.weightKg.map { unit.format(kg: $0) } ?? ""
            repsText = plan.reps.map(String.init) ?? ""
            secondsText = plan.durationSeconds.map(String.init) ?? ""
        }
        .onChange(of: weightText) { _, text in
            plan.weightKg = WeightUnit.parse(text).map(unit.toKg)
        }
        .onChange(of: repsText) { _, text in
            plan.reps = Int(text)
        }
        .onChange(of: secondsText) { _, text in
            plan.durationSeconds = Int(text)
        }
    }

    private func input(text: Binding<String>, keyboard: UIKeyboardType, field: Field) -> some View {
        TextField("0", text: text)
            .keyboardType(keyboard)
            .focused($focus, equals: field)
            .font(.body.weight(.medium))
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .frame(maxWidth: .infinity, minHeight: 44)
            .fieldChrome(isFocused: focus == field)
    }

    private var kindBinding: Binding<SetKind> {
        Binding(get: { plan.kind }, set: { plan.kind = $0 })
    }
}
