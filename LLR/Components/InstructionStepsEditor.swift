import SwiftUI

/// Ordered how-to steps; blank steps are dropped on save rather than blocking it.
struct InstructionStepsEditor: View {
    @Binding var steps: [String]

    var body: some View {
        Section {
            ForEach(steps.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(index + 1).").monospacedDigit().foregroundStyle(.secondary)
                    // Guarded: after a delete SwiftUI can still evaluate a row for an index that's gone,
                    // and `$steps[index]` would crash out of range.
                    TextField("Describe this step", text: Binding(
                        get: { steps.indices.contains(index) ? steps[index] : "" },
                        set: { if steps.indices.contains(index) { steps[index] = $0 } }
                    ), axis: .vertical)
                }
            }
            .onDelete { steps.remove(atOffsets: $0) }
            .onMove { steps.move(fromOffsets: $0, toOffset: $1) }
            Button {
                steps.append("")
            } label: {
                Label("Add Step", systemImage: "plus")
            }
        } header: {
            HStack {
                Text("How to")
                Spacer()
                if steps.count > 1 { EditButton().font(.footnote) }
            }
        }
    }
}
