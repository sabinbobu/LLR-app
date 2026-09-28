import SwiftUI

/// The catalog's own detail page — never the gym how-to, which can contradict a Kineto dose
/// (gym Plank says "hold as long as possible"; Kineto prescribes 5 × 30 s). `onAdd` is non-nil
/// only when this is opened from a picker, and adds the currently selected dosing level.
struct KinetoExerciseDetailView: View {
    let exercise: KinetoCatalog.Exercise
    /// The stored row behind the entry. It holds your notes and media, and for a user-made exercise
    /// every field; nil only if library seeding never created it.
    var row: Exercise? = nil
    var onAdd: ((KinetoCatalog.Level) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.kinetoDirection) private var directionRaw = KinetoDirectionPreference.notAssessed.rawValue
    @State private var selectedLevel: KinetoCatalog.Level?
    @State private var editing = false
    @State private var personalizing = false
    @State private var confirmingPrescription = false

    private var custom: Exercise? { row?.isCustomKineto == true ? row : nil }
    /// Re-read from the model so an edit shows up without reopening the page.
    private var shown: KinetoCatalog.Exercise { custom?.customKinetoSpec ?? exercise }

    private var level: KinetoCatalog.Level { selectedLevel ?? shown.levels[0] }
    private var direction: KinetoDirectionPreference { KinetoDirectionPreference(rawValue: directionRaw) ?? .notAssessed }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if custom != nil { origin }
                if let row, !row.media.isEmpty {
                    ExerciseMediaSection(items: .constant(row.mediaItems))
                }
                if let notes = row?.personalNotes.nilIfBlank {
                    KinetoInfoCard(title: "My notes", text: notes, color: Theme.accent)
                }
                // Shown, never hiding the exercise: Long 2004 vs. Dettori 1995 disagree on how much
                // this matters, so the app surfaces it and lets the physio's judgment decide.
                if onAdd != nil, direction.warns(for: shown.direction) {
                    KinetoInfoCard(
                        title: "Direction warning",
                        text: "This is tagged \(shown.direction.title.lowercased()), the opposite of what you set as helpful. You can still add it — check with your physiotherapist first.",
                        color: .orange
                    )
                }
                dosing
                if let mistakes = shown.mistakes {
                    KinetoInfoCard(title: "Common mistakes", text: mistakes, color: .secondary)
                }
                if let cautions = shown.cautions {
                    KinetoInfoCard(title: "Cautions", text: cautions, color: .orange)
                }
                if !shown.howto.isEmpty { ExerciseStepsView(steps: shown.howto) }
                if row != nil, custom == nil {
                    Button { personalizing = true } label: {
                        Label(hasPersonalContent ? "Edit my notes & media" : "Add my notes, photos or videos", systemImage: "camera")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(CardButtonStyle())
                }
                if !shown.sources.isEmpty { KinetoSourcesList(sources: shown.sources) }
            }
            .padding(16)
            .padding(.bottom, onAdd == nil ? 8 : 80)
        }
        .background(Theme.background)
        .navigationTitle(shown.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            if custom != nil {
                ToolbarItem(placement: .topBarLeading) { Button("Edit") { editing = true } }
            }
        }
        // A level picked before an edit would otherwise still add the old dose.
        .onChange(of: editing) { selectedLevel = nil }
        .sheet(isPresented: $editing) {
            if let custom { ExerciseEditorView(editing: custom) }
        }
        .sheet(isPresented: $personalizing) {
            if let row { KinetoPersonalEditor(exercise: row) }
        }
        .safeAreaInset(edge: .bottom) {
            if let onAdd {
                Button("Add — \(level.doseText)") {
                    if shown.prescribedOnly { confirmingPrescription = true } else { onAdd(level) }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
        }
        .confirmationDialog(
            "Only add this if your physiotherapist prescribed it for you.",
            isPresented: $confirmingPrescription, titleVisibility: .visible
        ) {
            Button("It was prescribed to me") { onAdd?(level) }
        }
    }

    private var hasPersonalContent: Bool {
        guard let row else { return false }
        return !row.media.isEmpty || row.personalNotes.nilIfBlank != nil
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(shown.category.title)
            Text("·")
            Text(shown.direction.title)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    @ViewBuilder private var origin: some View {
        if let prescriber = shown.sources.first(where: \.isPrescription) {
            KinetoInfoCard(title: "Prescribed by \(prescriber.title)", text: "Added by you from their prescription.", color: .secondary)
        } else {
            KinetoInfoCard(title: "Added by you", text: "Not from the cited catalog. Check the dose with your physiotherapist.", color: .secondary)
        }
    }

    private var dosing: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dosing").sectionLabel()
            VStack(spacing: 0) {
                ForEach(Array(shown.levels.enumerated()), id: \.offset) { index, lvl in
                    Button { selectedLevel = lvl } label: { levelRow(lvl, isSelected: lvl == level) }
                        .buttonStyle(.plain)
                        .disabled(onAdd == nil)
                    if index < shown.levels.count - 1 { Divider().padding(.leading, 16) }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
        }
    }

    private func levelRow(_ lvl: KinetoCatalog.Level, isSelected: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(lvl.label).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                if let notes = lvl.notes {
                    Text(notes).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text(lvl.doseText).font(.subheadline.weight(.semibold)).monospacedDigit()
            if onAdd != nil {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.accent : Color(.systemGray3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
