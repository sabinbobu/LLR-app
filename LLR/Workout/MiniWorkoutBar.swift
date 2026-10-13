import SwiftUI

/// Shown on every tab while a workout is open but minimised.
struct MiniWorkoutBar: View {
    let workout: Workout
    let timer: RestTimer
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional").foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 0) {
                    Text(workout.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(workout.startedAt, style: .timer)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let start = timer.startDate, let end = timer.endDate, start < end {
                    Label {
                        Text(timerInterval: start...end, countsDown: true).monospacedDigit()
                    } icon: {
                        Image(systemName: "timer")
                    }
                    .font(.subheadline.weight(.semibold))
                }
                Image(systemName: "chevron.up").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Resume workout \(workout.title)")
    }
}
