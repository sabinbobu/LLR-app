import SwiftUI

/// A standing note on the exercise itself ("seat 4, pin 7"), not on one session: the card shows it
/// every time the exercise is logged. It is the same `personalNotes` Kineto edits, so a
/// physiotherapist's cue turns up in the workout too.
struct ExerciseNoteEditor: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @FocusState private var focused: Bool

    init(exercise: Exercise) {
        self.exercise = exercise
        _text = State(initialValue: exercise.personalNotes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Multi-line: a note written in Kineto can run to several lines, and a
                    // single-line field would flatten it.
                    TextField("e.g. seat 4, pin 7", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .focused($focused)
                } footer: {
                    Text("Shown on this exercise every time you log it.")
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        exercise.personalNotes = text.nilIfBlank ?? ""
                        dismiss()
                    }
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}
