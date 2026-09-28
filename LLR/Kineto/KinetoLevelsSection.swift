import SwiftUI

/// A user-made exercise's dosing levels, easiest first, in the cited catalog's shape. Each level is
/// edited on its own page holding a copy, so a swipe-delete can never leave an editor bound to a
/// row that's gone.
struct KinetoLevelsSection: View {
    @Binding var levels: [KinetoCatalog.Level]

    var body: some View {
        Section {
            ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                NavigationLink {
                    KinetoLevelEditor(title: "Edit Level", level: level) { saved in
                        if levels.indices.contains(index) { levels[index] = saved }
                    }
                } label: {
                    row(level)
                }
                // The detail page and the add-at-a-dose flow both need a level to show.
                .deleteDisabled(levels.count == 1)
            }
            .onDelete { levels.remove(atOffsets: $0) }
            .onMove { levels.move(fromOffsets: $0, toOffset: $1) }
            NavigationLink {
                KinetoLevelEditor(title: "New Level", level: nextLevel) { levels.append($0) }
            } label: {
                Label("Add Level", systemImage: "plus")
            }
        } header: {
            HStack {
                Text("Levels")
                Spacer()
                if levels.count > 1 { EditButton().font(.footnote) }
            }
        } footer: {
            Text("Easiest first. You pick a level when adding the exercise to a routine or workout.")
        }
    }

    /// Starts from the hardest level so far, since a new one is usually a small step up from it.
    private var nextLevel: KinetoCatalog.Level {
        var level = levels.last ?? KinetoCatalog.Level(label: "", sets: 3, reps: 10, durationSeconds: nil, notes: nil)
        level.label = "Level \(levels.count + 1)"
        level.notes = nil
        return level
    }

    private func row(_ level: KinetoCatalog.Level) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(level.label)
                if let notes = level.notes {
                    Text(notes).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            Text(level.doseText).foregroundStyle(.secondary).monospacedDigit()
        }
    }
}
