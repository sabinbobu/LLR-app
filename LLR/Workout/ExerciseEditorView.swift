import SwiftData
import SwiftUI

/// Creates or edits a user-made exercise for either section. Media files are written as they are
/// added but only attached on Save; Cancel removes the ones this session added. Deleting lives in
/// the lists instead: a detail page still showing a deleted model would read freed data.
struct ExerciseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]
    @State private var draft: CustomExerciseDraft
    @State private var mediaSession = ExerciseMediaSession()
    private let original: CustomExerciseDraft
    private let editing: Exercise?
    let onSave: (Exercise) -> Void

    init(section: WorkoutSection, initialName: String = "", onSave: @escaping (Exercise) -> Void) {
        let draft = CustomExerciseDraft(section: section, name: initialName)
        _draft = State(initialValue: draft)
        original = draft
        editing = nil
        self.onSave = onSave
    }

    init(editing exercise: Exercise, onSave: @escaping (Exercise) -> Void = { _ in }) {
        let draft = CustomExerciseDraft(exercise)
        _draft = State(initialValue: draft)
        original = draft
        editing = exercise
        self.onSave = onSave
    }

    private var problem: CustomExerciseDraft.Problem? {
        draft.problem(existingNames: exercises.map(\.name), originalName: editing?.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise name", text: $draft.name)
                    Picker("Muscle group", selection: $draft.muscleGroup) {
                        ForEach(MuscleGroup.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                } footer: {
                    // An empty name already shows as a disabled Save; the rest need saying.
                    if let problem, problem != .emptyName { Text(problem.message).foregroundStyle(.red) }
                }
                MuscleEquipmentFields(draft: $draft)
                switch draft.section {
                case .gym: GymExerciseFields(draft: $draft)
                case .kineto: KinetoExerciseFields(draft: $draft)
                }
                InstructionStepsEditor(steps: $draft.instructions)
                if draft.section == .kineto {
                    KinetoSourcesSection(sources: $draft.kinetoSources)
                }
                Section("Photos & videos") {
                    ExerciseMediaSection(items: $draft.media, editable: true, session: mediaSession)
                }
            }
            .navigationTitle(editing == nil ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(draft != original || mediaSession.hasWritten)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(problem != nil)
                }
            }
        }
    }

    private func cancel() {
        mediaSession.cancel()
        dismiss()
    }

    private func save() {
        let exercise = editing ?? Exercise(name: draft.trimmedName, muscleGroup: draft.muscleGroup, isCustom: true)
        if editing == nil { context.insert(exercise) }
        draft.apply(to: exercise)
        exercise.syncMedia(to: draft.media, in: context)
        mediaSession.commit(keeping: draft.media)
        dismiss()
        onSave(exercise)
    }
}
