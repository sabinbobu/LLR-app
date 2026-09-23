import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        List {
            Section {
                LabeledContent("Started", value: workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Duration", value: Format.duration(workout.duration))
                LabeledContent("Volume", value: "\(unit.format(kg: workout.volumeKg)) \(unit.rawValue)")
            }
            ForEach(workout.orderedExercises) { entry in
                Section(entry.exercise?.name ?? "Exercise") {
                    ForEach(Array(entry.completedSets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("\(index + 1)").foregroundStyle(.secondary).frame(width: 28, alignment: .leading)
                            Text("\(unit.format(kg: set.weightKg)) \(unit.rawValue) × \(set.reps)")
                            Spacer()
                            Text("1RM \(unit.format(kg: OneRepMax.epley(set.value)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .monospacedDigit()
                    }
                }
            }
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Image(systemName: "trash")
            }
        }
        .confirmationDialog("Delete this workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) {
                dismiss()
                context.delete(workout)
            }
        }
    }
}
