import Charts
import SwiftUI

struct ExerciseProgressView: View {
    let exercise: Exercise
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var metric: Metric = .oneRepMax

    enum Metric: String, CaseIterable {
        case heaviest = "Heaviest Weight"
        case oneRepMax = "One Rep Max"
    }

    private var sessions: [Session] { exercise.sessions() }

    private var points: [ExerciseProgress.Point] {
        metric == .heaviest
            ? ExerciseProgress.heaviestWeightSeries(sessions)
            : ExerciseProgress.oneRepMaxSeries(sessions)
    }

    var body: some View {
        let best = ExerciseProgress.bestSet(in: sessions)
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
                Divider().padding(.horizontal, 16)
                recordRow("Estimated 1RM", value: best.map { "\(unit.format(kg: OneRepMax.epley($0))) \(unit.rawValue)" })
            }
            .cardStyle()
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
                (Text("\(unit.format(kg: last.value)) \(unit.rawValue) ").bold()
                    + Text(last.date.formatted(date: .abbreviated, time: .omitted)))
                    .font(.title3)
            }
            Chart(points, id: \.date) { point in
                LineMark(x: .value("Date", point.date), y: .value(metric.rawValue, unit.fromKg(point.value)))
                PointMark(x: .value("Date", point.date), y: .value(metric.rawValue, unit.fromKg(point.value)))
            }
            .foregroundStyle(Theme.accent)
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 200)

            HStack {
                ForEach(Metric.allCases, id: \.self) { option in
                    Button(option.rawValue) { metric = option }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(metric == option ? Color.white : Color.primary)
                        .background(metric == option ? Theme.accent : Theme.field, in: Capsule())
                        .buttonStyle(.plain)
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
