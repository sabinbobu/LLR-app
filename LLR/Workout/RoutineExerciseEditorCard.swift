import SwiftUI

struct RoutineExerciseEditorCard: View {
    let entry: RoutineExercise
    let unit: WeightUnit
    let onRemove: () -> Void
    let onAddSet: () -> Void
    let onDeleteSet: (RoutineSetPlan) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Image(systemName: "dumbbell.fill")
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Theme.border))
                Text(entry.exercise?.name ?? "Exercise")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Theme.accent)
                Spacer()
                Menu {
                    Button("Remove Exercise", systemImage: "trash", role: .destructive, action: onRemove)
                } label: {
                    Image(systemName: "ellipsis").frame(width: 44, height: 44)
                }
            }

            TextField("Add routine notes here", text: notesBinding, axis: .vertical)
                .foregroundStyle(.secondary)

            restMenu

            VStack(spacing: 0) {
                header
                let sets = entry.orderedSets
                let labels = SetKind.labels(for: sets.map(\.kind))
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, plan in
                    RoutineSetRowView(plan: plan, label: labels[index], unit: unit)
                        .background(index.isMultiple(of: 2) ? Theme.card : Color.clear)
                        .contextMenu {
                            Button("Delete Set", systemImage: "trash", role: .destructive) { onDeleteSet(plan) }
                        }
                }
            }
            .padding(.horizontal, -16)

            Button(action: onAddSet) {
                Label("Add Set", systemImage: "plus").frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(CardButtonStyle())
        }
    }

    private var notesBinding: Binding<String> {
        Binding(get: { entry.notes }, set: { entry.notes = $0 })
    }

    /// Unset (nil) reads as Off here, unlike the workout screen where unset means "use the global default".
    private var restMenu: some View {
        let current = entry.restSeconds.map(RestDuration.label) ?? "OFF"
        return Menu {
            Button("Off") { entry.restSeconds = nil }
            ForEach(RestDuration.choices, id: \.self) { seconds in
                Button(RestDuration.label(seconds)) { entry.restSeconds = seconds }
            }
        } label: {
            Label("Rest Timer: \(current)", systemImage: "timer")
                .foregroundStyle(Theme.accent)
        }
    }

    private var header: some View {
        HStack {
            Text("SET").frame(width: 56)
            Text(unit.rawValue.uppercased()).frame(maxWidth: .infinity)
            Text("REPS").frame(maxWidth: .infinity)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(height: 28)
    }
}
