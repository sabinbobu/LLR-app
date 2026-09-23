import SwiftUI

struct ExerciseLogCard: View {
    let entry: WorkoutExercise
    let model: ActiveWorkoutModel
    let unit: WeightUnit
    @State private var plateTargetKg: Double?

    private var showingPlates: Binding<Bool> {
        Binding(get: { plateTargetKg != nil }, set: { if !$0 { plateTargetKg = nil } })
    }

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
                    Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                        model.remove(entry)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                }
            }

            if let exercise = entry.exercise {
                restMenu(for: exercise)
            }

            VStack(spacing: 0) {
                header
                let sets = entry.orderedSets
                let labels = SetKind.labels(for: sets.map(\.kind))
                let records = entry.recordKinds()
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                    SetRowView(
                        entry: set,
                        label: labels[index],
                        unit: unit,
                        isStriped: index.isMultiple(of: 2),
                        isRecord: !records[index].isEmpty
                    ) {
                        model.toggle(set)
                    }
                    .contextMenu {
                        Button("Plate Calculator", systemImage: "circle.grid.2x1") { plateTargetKg = set.weightKg }
                        Button("Delete Set", systemImage: "trash", role: .destructive) { model.delete(set) }
                    }
                }
            }
            .padding(.horizontal, -16)

            Button {
                model.addSet(to: entry)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(CardButtonStyle())
        }
        .sheet(isPresented: showingPlates) {
            PlateCalculatorView(unit: unit, targetKg: plateTargetKg ?? 0)
        }
    }

    /// Per-exercise because rest needs differ wildly: 3 min after heavy squats, 45 s after curls.
    private func restMenu(for exercise: Exercise) -> some View {
        let fallback: Int = model.defaultRestSeconds
        let current: String = exercise.restSeconds.map(RestDuration.label) ?? "\(RestDuration.label(fallback)) (default)"
        return Menu {
            Button("Default (\(RestDuration.label(fallback)))") { exercise.restSeconds = nil }
            ForEach(RestDuration.choices, id: \.self) { seconds in
                Button(RestDuration.label(seconds)) { exercise.restSeconds = seconds }
            }
            Button("Off") { exercise.restSeconds = 0 }
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
            Image(systemName: "checkmark").frame(width: 64)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(height: 32)
    }
}
