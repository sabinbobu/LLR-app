import SwiftUI

/// A transient banner celebrating a new record; auto-dismisses so it never blocks logging the next set.
struct PRBanner: View {
    let event: RecordEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("New PR! \(event.exerciseName)")
                    .font(.subheadline.weight(.semibold))
                Text(event.kinds.map(\.title).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.yellow, lineWidth: 1.5))
        .shadow(radius: 8, y: 2)
        .padding(.horizontal)
    }
}
