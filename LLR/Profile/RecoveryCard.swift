import SwiftUI

/// Profile-tab summary: an overall recovery ring plus the muscles that need the most time, before
/// opening `MuscleRecoveryView` for the full breakdown.
struct RecoveryCard: View {
    let workouts: [Workout]

    private var statuses: [MuscleGroup: MuscleRecovery.Status] {
        MuscleRecoveryInput.statuses(for: workouts)
    }

    private var overall: Double { MuscleRecoveryInput.overall(for: workouts) }

    private var leastRecovered: [MuscleRecovery.Status] {
        Array(statuses.values.sorted { $0.percent < $1.percent }.prefix(4))
    }

    var body: some View {
        NavigationLink {
            MuscleRecoveryView(workouts: workouts)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Muscle Recovery").font(.title3.weight(.semibold)).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                HStack(spacing: 20) {
                    RecoveryRing(percent: overall)
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(leastRecovered, id: \.muscle) { status in
                            HStack {
                                Text(status.muscle.rawValue).font(.subheadline)
                                Spacer()
                                Text("\(Int(status.percent))%")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.recoveryColor(status.percent))
                            }
                        }
                    }
                }
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

/// Shared by the summary card and the detail screen's header.
struct RecoveryRing: View {
    let percent: Double

    var body: some View {
        ZStack {
            Circle().stroke(Theme.border, lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0.02, percent / 100))
                .stroke(Theme.recoveryColor(percent), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: percent)
            Text("\(Int(percent))%").font(.headline).monospacedDigit()
        }
    }
}

/// Shared math both recovery views need: only the last 4 days feed the model, matching the longest
/// recovery window (72h) with a day's buffer, and it's cheap to recompute since a session rarely
/// holds more than a handful of finished workouts in that span.
enum MuscleRecoveryInput {
    private static func recent(_ workouts: [Workout], now: Date) -> [Workout] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -4, to: now) ?? .distantPast
        return workouts.filter { $0.startedAt >= cutoff }
    }

    static func statuses(for workouts: [Workout], now: Date = .now) -> [MuscleGroup: MuscleRecovery.Status] {
        let entries = recent(workouts, now: now).flatMap(\.exhaustionEntries)
        return MuscleRecovery.statuses(for: entries, now: now)
    }

    /// Whole-body exhaustion (0–100) still left from recent runs.
    static func systemicExhaustion(for workouts: [Workout], now: Date = .now) -> Double {
        let total = recent(workouts, now: now).reduce(0.0) { sum, workout in
            guard let percent = workout.runExhaustionPercent, let finished = workout.endedAt else { return sum }
            let hours = now.timeIntervalSince(finished) / 3600
            return sum + RunLoad.remainingExhaustion(percent, hoursSince: hours)
        }
        return min(100, total)
    }

    static func overall(for workouts: [Workout], now: Date = .now) -> Double {
        MuscleRecovery.overallPercent(statuses(for: workouts, now: now),
                                      systemicExhaustion: systemicExhaustion(for: workouts, now: now))
    }
}
