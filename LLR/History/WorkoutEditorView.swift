import SwiftData
import SwiftUI

/// Edits a finished workout, or logs one after the fact, with the same cards as a live session.
/// Changes apply as you go; Cancel puts the workout back from a snapshot taken on open.
struct WorkoutEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var model: ActiveWorkoutModel
    @State private var original: WorkoutSnapshot
    @State private var showingPicker = false
    private let isNew: Bool

    init(workout: Workout, isNew: Bool = false) {
        _model = State(initialValue: ActiveWorkoutModel(workout: workout, isHistory: true))
        _original = State(initialValue: WorkoutSnapshot(workout))
        self.isNew = isNew
    }

    private var workout: Workout { model.workout }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    details
                    ForEach(workout.orderedExercises) { entry in
                        ExerciseLogCard(entry: entry, model: model, unit: unit)
                    }
                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isNew ? "Log Past Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerView { $0.forEach(model.add) }
            }
        }
        .interactiveDismissDisabled()
    }

    private var details: some View {
        VStack(spacing: 12) {
            TextField(workout.title, text: Binding(get: { workout.name }, set: { workout.name = $0 }))
                .font(.title3.weight(.medium))
            Divider()
            DatePicker("Started", selection: startBinding, in: ...Date.now)
            DatePicker("Ended", selection: endBinding, in: workout.startedAt...max(workout.startedAt, .now))
            Divider()
            TextField("Add private notes", text: Binding(get: { workout.notes }, set: { workout.notes = $0 }), axis: .vertical)
                .lineLimit(1...4)
        }
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    /// Moving the start keeps the length, so fixing a wrong date doesn't also change the duration.
    private var startBinding: Binding<Date> {
        Binding(get: { workout.startedAt }, set: { workout.reschedule(startingAt: $0) })
    }

    private var endBinding: Binding<Date> {
        Binding(get: { workout.endedAt ?? workout.startedAt }, set: { workout.endedAt = max($0, workout.startedAt) })
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", action: cancel)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                model.saveEdits()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            // With no ticked sets there'd be nothing to keep; deleting is the detail screen's job.
            .disabled(workout.completedSets.isEmpty)
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }

    private func cancel() {
        if isNew {
            context.delete(workout)
        } else {
            original.restore(into: workout, in: context)
        }
        try? context.save()
        dismiss()
    }
}
