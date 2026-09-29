import SwiftUI

struct KinetoSourcesList: View {
    let sources: [KinetoCatalog.Source]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sources").sectionLabel()
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(sources.enumerated()), id: \.offset) { _, source in
                    if let link = source.link {
                        Link(destination: link) { label(source, color: Theme.accent) }
                    } else {
                        label(source, color: .primary)
                    }
                }
            }
        }
    }

    private func label(_ source: KinetoCatalog.Source, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(source.title).font(.subheadline).foregroundStyle(color)
            Text(source.kindTitle).font(.caption).foregroundStyle(.secondary)
        }
    }
}
