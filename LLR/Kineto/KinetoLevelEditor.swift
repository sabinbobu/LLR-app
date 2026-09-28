import SwiftUI

/// Edits a copy of one level; only Done hands it back, so Cancel really discards.
struct KinetoLevelEditor: View {
    let title: String
    let onSave: (KinetoCatalog.Level) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var level: KinetoCatalog.Level

    init(title: String, level: KinetoCatalog.Level, onSave: @escaping (KinetoCatalog.Level) -> Void) {
        self.title = title
        self.onSave = onSave
        _level = State(initialValue: level)
    }

    var body: some View {
        Form {
            Section {
                TextField("Label, e.g. L1 — From knees", text: $level.label)
            }
            Section {
                numberField("Sets", value: $level.sets)
                numberField("Reps", value: $level.reps)
                numberField("Hold (seconds)", value: $level.durationSeconds)
                LabeledContent("Shows as", value: level.cleaned(fallbackLabel: "").doseText)
            } header: {
                Text("Dose")
            } footer: {
                Text("Leave a field empty if it doesn't apply, e.g. no reps for a timed hold.")
            }
            Section("Notes") {
                TextField("e.g. Each side. Daily.", text: notesBinding, axis: .vertical)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    onSave(level.cleaned(fallbackLabel: title))
                    dismiss()
                }
                .disabled(level.label.nilIfBlank == nil)
            }
        }
    }

    private var notesBinding: Binding<String> {
        Binding(get: { level.notes ?? "" }, set: { level.notes = $0 })
    }

    private func numberField(_ title: String, value: Binding<Int?>) -> some View {
        LabeledContent(title) {
            TextField("—", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
    }
}
