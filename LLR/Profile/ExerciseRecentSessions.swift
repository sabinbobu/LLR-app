import SwiftUI

/// The sessions behind the last points of the progress chart, set by set.
struct ExerciseRecentSessions: View {
    /// Newest first.
    let sessions: [Session]
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Sessions").sectionLabel()
            VStack(spacing: 0) {
                ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                    if index > 0 { Divider().padding(.horizontal, 16) }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.semibold))
                        Text(ExerciseProgress.setsText(session.sets, unit: unit))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .cardStyle()
        }
    }
}
