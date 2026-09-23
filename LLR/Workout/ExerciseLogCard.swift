import SwiftUI

struct ExerciseLogCard: View {
    let entry: WorkoutExercise
    let model: ActiveWorkoutModel
    let unit: WeightUnit

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

            VStack(spacing: 0) {
                header
                ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                    SetRowView(entry: set, number: index + 1, unit: unit, isStriped: index.isMultiple(of: 2)) {
                        model.toggle(set)
                    }
                    .contextMenu {
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
