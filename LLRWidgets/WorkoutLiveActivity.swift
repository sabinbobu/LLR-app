import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockScreenView(attributes: context.attributes, state: context.state, isStale: context.isStale)
        } dynamicIsland: { context in
            let state = context.state
            let resting = state.isResting && !context.isStale
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(state.exerciseName ?? "All sets done", systemImage: "dumbbell.fill")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if resting, let start = state.restStartedAt, let end = state.restEndsAt {
                        Text(timerInterval: start...end, countsDown: true)
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Color.llrAccent)
                            .frame(maxWidth: 72)
                    } else {
                        Text("\(state.completedSets)/\(state.totalSets)").font(.subheadline.monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(state.setLabel) · \(state.target)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            CompleteSetButton(state: state)
                        }
                        if resting {
                            RestControls(state: state, showsCountdown: false)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill").foregroundStyle(Color.llrAccent)
            } compactTrailing: {
                if resting, let start = state.restStartedAt, let end = state.restEndsAt {
                    Text(timerInterval: start...end, countsDown: true)
                        .monospacedDigit()
                        .frame(maxWidth: 44)
                        .foregroundStyle(Color.llrAccent)
                } else {
                    Text("\(state.completedSets)/\(state.totalSets)").monospacedDigit()
                }
            } minimal: {
                Image(systemName: resting ? "timer" : "dumbbell.fill").foregroundStyle(Color.llrAccent)
            }
            .keylineTint(Color.llrAccent)
        }
    }
}

struct WorkoutLockScreenView: View {
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState
    let isStale: Bool

    private var resting: Bool { state.isResting && !isStale }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(attributes.workoutName, systemImage: "dumbbell.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.llrAccent)
                Spacer()
                Text(attributes.startedAt, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            // Done keeps one position in every state: at the rack, muscle memory beats reading.
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.exerciseName ?? "All sets done")
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(state.setLabel) · \(state.target)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                CompleteSetButton(state: state)
            }
            if resting, let start = state.restStartedAt, let end = state.restEndsAt {
                ProgressView(timerInterval: start...end, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(Color.llrAccent)
                RestControls(state: state, showsCountdown: true)
            }
        }
        .padding(16)
    }
}

struct CompleteSetButton: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        if state.canComplete {
            Button(intent: CompleteSetIntent()) {
                Label("Done", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .fixedSize()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.llrAccent)
            .accessibilityLabel("Complete \(state.setLabel)")
        }
    }
}

struct RestControls: View {
    let state: WorkoutActivityAttributes.ContentState
    let showsCountdown: Bool

    var body: some View {
        HStack(spacing: 8) {
            if showsCountdown, let start = state.restStartedAt, let end = state.restEndsAt {
                Text(timerInterval: start...end, countsDown: true)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .accessibilityLabel("Rest remaining")
            }
            Spacer(minLength: 0)
            Button(intent: AdjustRestIntent(seconds: -15)) { Text("−15") }
                .accessibilityLabel("Rest 15 seconds less")
            Button(intent: AdjustRestIntent(seconds: 15)) { Text("+15") }
                .accessibilityLabel("Rest 15 seconds more")
            Button(intent: SkipRestIntent()) { Text("Skip") }
        }
        .buttonStyle(.bordered)
        .tint(Color.llrAccent)
        .font(.subheadline.weight(.medium))
    }
}
