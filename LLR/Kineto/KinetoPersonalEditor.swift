import SwiftData
import SwiftUI

/// Your own notes, photos and videos on a cited catalog exercise, e.g. your physiotherapist filming
/// how they want it done. The cited fields stay read-only, so what's attributed to a source is only
/// ever what that source says. Media files are written as they're added; Cancel removes new ones.
struct KinetoPersonalEditor: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var notes: String
    @State private var media: [ExerciseMediaItem]
    @State private var mediaSession = ExerciseMediaSession()
    private let originalNotes: String
    private let originalMedia: [ExerciseMediaItem]

    init(exercise: Exercise) {
        self.exercise = exercise
        originalNotes = exercise.personalNotes
        originalMedia = exercise.mediaItems
        _notes = State(initialValue: originalNotes)
        _media = State(initialValue: originalMedia)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. what your physiotherapist corrected", text: $notes, axis: .vertical)
                } header: {
                    Text("My notes")
                }
                Section("Photos & videos") {
                    ExerciseMediaSection(items: $media, editable: true, session: mediaSession)
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(notes != originalNotes || media != originalMedia || mediaSession.hasWritten)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        mediaSession.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        exercise.personalNotes = notes.nilIfBlank ?? ""
                        exercise.syncMedia(to: media, in: context)
                        mediaSession.commit(keeping: media)
                        dismiss()
                    }
                }
            }
        }
    }
}
