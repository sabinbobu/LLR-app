import SwiftUI

/// Where a user-made exercise comes from: usually the physiotherapist who prescribed it.
struct KinetoSourcesSection: View {
    @Binding var sources: [KinetoCatalog.Source]

    var body: some View {
        Section {
            ForEach(Array(sources.enumerated()), id: \.offset) { index, source in
                NavigationLink {
                    KinetoSourceEditor(title: "Edit Source", source: source) { saved in
                        if sources.indices.contains(index) { sources[index] = saved }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.title).lineLimit(1)
                        Text(source.kindTitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { sources.remove(atOffsets: $0) }
            NavigationLink {
                KinetoSourceEditor(
                    title: "New Source",
                    source: KinetoCatalog.Source(title: "", url: nil, kind: KinetoCatalog.SourceKind.physiotherapist.rawValue)
                ) { sources.append($0) }
            } label: {
                Label("Add Source", systemImage: "plus")
            }
        } header: {
            Text("Sources")
        } footer: {
            Text("With your physiotherapist as a source, the exercise shows as prescribed by them.")
        }
    }
}
