import Charts
import SwiftUI

struct ExerciseProgressView: View {
    let exercise: Exercise
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @AppStorage(StorageKey.effortScale) private var effortScale: EffortScale = .off
    @State private var picked: ExerciseProgress.Metric = .oneRepMax

    private var sessions: [Session] { exercise.sessions() }
    private var assisted: Bool { ExerciseProgress.isAssisted(name: exercise.name) }

    private var metrics: [ExerciseProgress.Metric] {
        let rated = effortScale != .off && sessions.contains { $0.sets.contains { $0.rir != nil } }
        return ExerciseProgress.metrics(assisted: assisted, rated: rated)
    }

    /// The pick can be one this exercise doesn't offer (an assisted machine has no one-rep max).
    private var metric: ExerciseProgress.Metric { metrics.contains(picked) ? picked : metrics[0] }

    private var points: [ExerciseProgress.Point] {
        ExerciseProgress.series(sessions, metric: metric, assisted: assisted)
    }

    var body: some View {
        let best = ExerciseProgress.bestSet(in: sessions, assisted: assisted)
        let recent = ExerciseProgress.recent(sessions)
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress").sectionLabel()
            VStack(spacing: 0) {
                if sessions.isEmpty {
                    emptyState
                } else {
                    chart
                }
                Divider().padding(.horizontal, 16)
                recordRow("Best set", value: best.map { "\(unit.format(kg: $0.weightKg)) \(unit.rawValue) × \($0.reps)" })
                if !assisted {
                    Divider().padding(.horizontal, 16)
                    recordRow("Estimated 1RM", value: best.map { "\(unit.format(kg: OneRepMax.epley($0))) \(unit.rawValue)" })
                }
            }
            .cardStyle()
            if !recent.isEmpty {
                ExerciseRecentSessions(sessions: recent, unit: unit)
                    .padding(.top, 16)
            }
        }
    }

    /// Chart-axis number: weights in the display unit, effort on the scale the lifter rates in.
    private func plotted(_ value: Double) -> Double {
        switch metric {
        case .oneRepMax, .topSet: unit.fromKg(value)
        case .maxReps: value
        case .effort: effortScale == .rpe ? 10 - value : value
        }
    }

    private func headline(_ value: Double) -> String {
        switch metric {
        case .oneRepMax, .topSet: "\(unit.format(kg: value)) \(unit.rawValue)"
        case .maxReps: "\(Int(value)) reps"
        case .effort: "\(effortScale.title) \(Effort.text(rir: value, scale: effortScale))"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No data yet").font(.headline)
            Text("Log this exercise in a workout to chart your estimated one-rep max.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let last = points.last {
                (Text("\(headline(last.value)) ").bold()
                    + Text(last.date.formatted(date: .abbreviated, time: .omitted)))
                    .font(.title3)
            }
            Chart(points, id: \.date) { point in
                LineMark(x: .value("Date", point.date), y: .value(metric.title(assisted: assisted), plotted(point.value)))
                PointMark(x: .value("Date", point.date), y: .value(metric.title(assisted: assisted), plotted(point.value)))
            }
            .foregroundStyle(Theme.accent)
            // Less help is the progress on an assisted machine, so that axis is flipped to keep "up is better".
            .chartYScale(domain: .automatic(includesZero: false, reversed: assisted && metric == .topSet))
            .frame(height: 200)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(metrics) { option in
                        Button(option.title(assisted: assisted)) { picked = option }
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(metric == option ? Color.white : Color.primary)
                            .background(metric == option ? Theme.accent : Theme.field, in: Capsule())
                            .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
    }

    private func recordRow(_ title: String, value: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "—")
                .fontWeight(.semibold)
                .foregroundStyle(value == nil ? Color.secondary : Color.primary)
        }
        .font(.subheadline)
        .monospacedDigit()
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
