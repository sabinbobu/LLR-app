import SwiftUI

/// Third-party attribution required by license, not marketing — keep this in sync with anything
/// ported into `LLR/Resources/` or `LLR/Components/`.
struct AcknowledgementsView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Body map data").font(.headline)
                    Text("Muscle outlines used by Recovery, the muscle split and workout summaries are adapted from react-body-highlighter.")
                    Text("MIT License — Copyright © 2020 GV79").foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("openGym").font(.headline)
                    Text("The activity heatmap shading, favourites ordering and workout text export follow logic from openGym by Duarte Santos.")
                    Text("github.com/DuarteSantos8/openGym").foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}
