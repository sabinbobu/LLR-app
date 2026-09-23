import SwiftUI

/// A planning row, not a logging row: no checkmark, and an empty field is a deliberate "blank"
/// rather than zero — `SetRowView` conflates "not logged yet" with completion, which doesn't apply here.
struct RoutineSetRowView: View {
    let plan: RoutineSetPlan
    let label: String
    let unit: WeightUnit

    @State private var weightText = ""
    @State private var repsText = ""

    var body: some View {
        HStack {
            Menu {
                Picker("Set type", selection: kindBinding) {
                    ForEach(SetKind.allCases) { Text($0.title).tag($0) }
                }
            } label: {
                Text(label)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(SetRowView.color(for: plan.kind))
                    .frame(width: 56, height: 44)
                    .contentShape(Rectangle())
            }
            TextField("-", text: $weightText)
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity)
            TextField("-", text: $repsText)
                .keyboardType(.numberPad)
                .frame(maxWidth: .infinity)
        }
        .font(.title3)
        .multilineTextAlignment(.center)
        .monospacedDigit()
        .frame(height: 44)
        .onAppear {
            weightText = plan.weightKg.map { unit.format(kg: $0) } ?? ""
            repsText = plan.reps.map(String.init) ?? ""
        }
        .onChange(of: weightText) { _, text in
            plan.weightKg = WeightUnit.parse(text).map(unit.toKg)
        }
        .onChange(of: repsText) { _, text in
            plan.reps = Int(text)
        }
    }

    private var kindBinding: Binding<SetKind> {
        Binding(get: { plan.kind }, set: { plan.kind = $0 })
    }
}
