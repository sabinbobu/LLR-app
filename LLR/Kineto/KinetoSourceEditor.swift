import SwiftUI

/// Edits a copy of one source; only Done hands it back, so Cancel really discards.
struct KinetoSourceEditor: View {
    let title: String
    let onSave: (KinetoCatalog.Source) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var source: KinetoCatalog.Source
    @State private var link: String

    init(title: String, source: KinetoCatalog.Source, onSave: @escaping (KinetoCatalog.Source) -> Void) {
        self.title = title
        self.onSave = onSave
        _source = State(initialValue: source)
        _link = State(initialValue: source.url ?? "")
    }

    private var kind: Binding<KinetoCatalog.SourceKind> {
        Binding(
            get: { KinetoCatalog.SourceKind(rawValue: source.kind) ?? .other },
            set: { source.kind = $0.rawValue }
        )
    }

    private var edited: KinetoCatalog.Source? {
        KinetoCatalog.Source(title: source.title, url: link, kind: source.kind).cleaned
    }

    private var linkIsValid: Bool { link.nilIfBlank.map(KinetoCatalog.Source.isValidURL) ?? true }

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: kind) {
                    ForEach(KinetoCatalog.SourceKind.allCases) { Text($0.title).tag($0) }
                }
                TextField(kind.wrappedValue == .physiotherapist ? "Name or clinic" : "Title", text: $source.title)
            }
            Section {
                TextField("https://", text: $link)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Link (optional)")
            } footer: {
                if !linkIsValid {
                    Text(CustomExerciseDraft.Problem.invalidSourceURL.message).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    if let edited { onSave(edited) }
                    dismiss()
                }
                .disabled(edited == nil || !linkIsValid)
            }
        }
    }
}
