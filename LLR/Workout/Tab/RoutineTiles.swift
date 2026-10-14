import SwiftUI

/// New Routine and Explore as two compact buttons under the quick-start rows.
struct RoutineTiles: View {
    let onNew: () -> Void
    let canStart: Bool
    let onStart: (ProgramTemplate, ProgramTemplate.Day) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onNew) {
                Label("New Routine", systemImage: "list.clipboard")
            }
            .buttonStyle(.secondaryRole)
            NavigationLink {
                ExploreRoutinesView(canStart: canStart, onStart: onStart)
            } label: {
                Label("Explore", systemImage: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            .buttonStyle(.plain)
        }
    }
}
