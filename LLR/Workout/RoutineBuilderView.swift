import SwiftData
import SwiftUI

struct RoutineBuilderView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var showingPicker = false

    private var trimmedName: String { routine.name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Routine title", text: $routine.name)
                }
                if routine.orderedExercises.isEmpty {
                    Section {
                        EmptyStateCard(systemImage: "dumbbell", message: "Get started by adding an exercise to your routine.")
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        Button("Add Exercise") { showingPicker = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                } else {
                    ForEach(routine.orderedExercises) { entry in
                        Section {
                            RoutineExerciseEditorCard(
                                entry: entry,
                                unit: unit,
                                onRemove: { context.delete(entry) },
                                onAddSet: { addSet(to: entry) },
                                onDeleteSet: { context.delete($0) }
                            )
                        }
                    }
                    Section {
                        Button("Add Exercise") { showingPicker = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Create Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        context.delete(routine)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        routine.name = trimmedName
                        try? context.save()
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .sheet(isPresented: $showingPicker) { ExercisePickerView { add($0) } }
        }
    }

    private func add(_ exercise: Exercise) {
        let entry = RoutineExercise(order: (routine.exercises.map(\.order).max() ?? -1) + 1)
        context.insert(entry)
        entry.exercise = exercise
        routine.exercises.append(entry)
        addSet(to: entry)
    }

    private func addSet(to entry: RoutineExercise) {
        let plan = RoutineSetPlan(order: (entry.sets.map(\.order).max() ?? -1) + 1)
        context.insert(plan)
        entry.sets.append(plan)
    }
}
