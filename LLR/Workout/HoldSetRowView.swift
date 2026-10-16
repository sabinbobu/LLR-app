import SwiftUI

/// A duration set (reps × seconds hold), e.g. Bird Dog 5 × 15 s. No weight column or plate
/// calculator — holds aren't loaded. Tapping the checkmark starts a live per-rep countdown shown
/// with `Text(timerInterval:)`, which the system ticks on its own; a single `Task.sleep` advances
/// to the next rep when it ends, so nothing here re-renders on every tick the way a shared,
/// observed `ActiveWorkoutModel` timer would.
struct HoldSetRowView: View {
    let entry: SetEntry
    let label: String
    let isStriped: Bool
    let isRecord: Bool
    let onToggle: () -> Bool

    @State private var repsText = ""
    @State private var secondsText = ""
    @State private var rejectCount = 0
    @State private var holdEndsAt: Date?
    @State private var holdRepsLeft = 0
    @State private var holdTask: Task<Void, Never>?

    private var isDone: Bool { entry.completedAt != nil }
    private var isHolding: Bool { holdEndsAt != nil }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Menu {
                    Picker("Set type", selection: kindBinding) {
                        ForEach(SetKind.allCases) { Text($0.title).tag($0) }
                    }
                } label: {
                    Text(label)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(SetRowView.color(for: entry.kind))
                        .frame(width: 56, height: 52)
                        .overlay(alignment: .topTrailing) {
                            if isRecord {
                                Image(systemName: "trophy.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                                    .padding(6)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .contentShape(Rectangle())
                }
                .animation(.bouncy, value: isRecord)
                .disabled(isHolding)
                TextField(entry.reps > 0 ? "\(entry.reps)" : "-", text: $repsText)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)
                    .disabled(isHolding)
                TextField(entry.durationSeconds.map { "\($0)" } ?? "-", text: $secondsText)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)
                    .disabled(isHolding)
                completeButton
            }
            .font(.title3)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .frame(height: 52)

            if let holdEndsAt {
                HStack(spacing: 4) {
                    Text(timerInterval: Date.now...holdEndsAt, countsDown: true)
                    Text(holdRepsLeft > 1 ? "· \(holdRepsLeft) reps left" : "· last rep")
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .monospacedDigit()
                .padding(.bottom, 8)
            }
        }
        .background(isDone ? Theme.completedRow : (isStriped ? Theme.card : Color.clear))
        .sensoryFeedback(.impact(weight: .medium), trigger: isDone)
        .sensoryFeedback(.error, trigger: rejectCount)
        .sensoryFeedback(.success, trigger: isRecord) { _, new in new }
        .onAppear { if isDone { fillTextFromModel() } }
        .onDisappear { holdTask?.cancel() }
        .onChange(of: repsText) { _, text in
            if let value = InputLimits.count(text) { entry.reps = value }
        }
        // Only a real hold is written: a cleared field (mid-retype) set nil, and one nil turns the
        // whole card into weight × reps rows, dropping this set's hold for good.
        .onChange(of: secondsText) { _, text in
            if let value = InputLimits.count(text, max: InputLimits.maxSeconds), value > 0 { entry.durationSeconds = value }
        }
    }

    private var completeButton: some View {
        Button {
            if isHolding {
                cancelHold()
            } else if isDone {
                _ = onToggle()
            } else {
                startHold()
            }
        } label: {
            Image(systemName: isHolding ? "xmark" : "checkmark")
                .font(.body.bold())
                .foregroundStyle(isDone ? Color.white : Color.secondary)
                .frame(width: 36, height: 36)
                .background(isDone ? Theme.completedCheck : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                .frame(width: 64, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The symbols' own labels ("Selected", "Close") would describe a set that isn't done as selected.
        .accessibilityLabel(isHolding ? "Stop hold" : isDone ? "Mark set not done" : "Complete set")
        .accessibilityValue(isDone ? "Done" : "Not done")
        .accessibilityIdentifier("set-check")
    }

    /// No hold recorded (shouldn't happen for a catalog set, but the field is user-editable):
    /// behaves like a plain tap-to-complete instead of stalling on a countdown that never starts.
    private func startHold() {
        guard entry.reps > 0, let duration = entry.durationSeconds, duration > 0 else {
            if !onToggle() { rejectCount += 1 }
            return
        }
        holdRepsLeft = entry.reps
        beginNextHold(duration: duration)
    }

    private func beginNextHold(duration: Int) {
        holdEndsAt = Date.now.addingTimeInterval(TimeInterval(duration))
        holdTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            finishedOneHold(duration: duration)
        }
    }

    private func finishedOneHold(duration: Int) {
        holdRepsLeft -= 1
        if holdRepsLeft > 0 {
            beginNextHold(duration: duration)
        } else {
            holdEndsAt = nil
            if onToggle() { fillTextFromModel() }
        }
    }

    private func cancelHold() {
        holdTask?.cancel()
        holdTask = nil
        holdEndsAt = nil
    }

    private var kindBinding: Binding<SetKind> {
        Binding(get: { entry.kind }, set: { entry.kind = $0 })
    }

    private func fillTextFromModel() {
        if repsText.isEmpty { repsText = "\(entry.reps)" }
        if secondsText.isEmpty { secondsText = entry.durationSeconds.map { "\($0)" } ?? "" }
    }
}
