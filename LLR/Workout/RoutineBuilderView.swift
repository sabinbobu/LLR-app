import SwiftData
import SwiftUI

struct RoutineBuilderView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var showingPicker = false
    /// Save requires a name, so a nameless routine was never saved: Cancel discards it.
    /// A saved routine opened for editing is only closed, never deleted.
    @State private var isNew: Bool
    @FocusState private var nameFocused: Bool

    init(routine: Routine) {
        _routine = Bindable(routine)
        _isNew = State(initialValue: routine.name.isEmpty)
    }

    private var trimmedName: String { routine.name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameField
                    exercises
                    Button { showingPicker = true } label: {
                        Label("Add exercise", systemImage: "plus")
                    }
                    .buttonStyle(SheetButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background)
            .navigationTitle("Create Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerView { $0.forEach(add) }
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Routine name").sectionLabel()
            TextField("e.g. Push Day", text: $routine.name)
                .focused($nameFocused)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .fieldChrome(isFocused: nameFocused, cornerRadius: 12, fill: Theme.surface)
        }
    }

    private var exercises: some View {
        let entries = routine.orderedExercises
        let setCount = entries.reduce(0) { $0 + $1.sets.count }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Exercises").font(.footnote.weight(.semibold))
                Spacer()
                if !entries.isEmpty {
                    Text("^[\(entries.count) exercise](inflect: true) · ^[\(setCount) set](inflect: true)")
                        .font(.footnote)
                }
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)

            if entries.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(entries) { entry in
                        RoutineExerciseEditorCard(
                            entry: entry,
                            unit: unit,
                            onRemove: { context.delete(entry) },
                            onAddSet: { addSet(to: entry) },
                            onDeleteSet: { context.delete($0) }
                        )
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "dumbbell")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.tertiary)
            Text("Get started by adding an exercise to your routine.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .cardStyle()
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if isNew { context.delete(routine) }
                dismiss()
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                routine.name = trimmedName
                try? context.save()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(trimmedName.isEmpty)
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
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
        // Save now: a deferred autosave re-renders the sheet a moment later and cancels
        // a card menu the user has just tapped open.
        try? context.save()
    }
}
