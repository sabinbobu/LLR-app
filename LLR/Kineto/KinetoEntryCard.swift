import SwiftUI

/// The Workout tab's entry point into Kineto — kept visually distinct from ordinary routines.
struct KinetoEntryCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.core.training")
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.accentSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Kineto — back care").font(.headline)
                Text("Physiotherapist-gated exercises for low-back pain")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .contentShape(Rectangle())
    }
}
