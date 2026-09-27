import Charts
import SwiftUI

struct WeeklyStatsCard: View {
    let summaries: [WorkoutSummary]
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var metric: Stats.Metric = .duration
    @State private var range: Stats.Range = .threeMonths

    private var weeks: Int { range.weeks(since: summaries.map(\.date).min()) }
    private var points: [Stats.WeekPoint] { Stats.weekly(summaries, metric: metric, weeks: weeks) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Range", selection: $range) {
                ForEach(Stats.Range.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if summaries.isEmpty {
                EmptyStateCard(systemImage: "chart.bar", message: "No data yet")
            } else {
                chart
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1.5))
            }
            HStack(spacing: 12) {
                ForEach(Stats.Metric.allCases) { option in
                    Button(option.rawValue) { metric = option }
                        .font(.title3)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .foregroundStyle(metric == option ? Color.white : Color.primary)
                        .background(metric == option ? Theme.accent : Theme.card, in: Capsule())
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private var chart: some View {
        let latest: Double = points.last?.value ?? 0
        return VStack(alignment: .leading, spacing: 8) {
            (Text(display(latest)).bold() + Text(" this week").foregroundColor(.secondary))
                .font(.title3)
            Chart(points) { point in
                BarMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value(metric.rawValue, plotted(point.value))
                )
                .foregroundStyle(Theme.accent)
                .cornerRadius(4)
            }
            .chartXAxis {
                // A full year-plus of weekly bars is too dense for a monthly axis to stay readable.
                AxisMarks(values: .stride(by: range == .all ? .quarter : .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 180)
            .animation(.snappy, value: metric)
            .animation(.snappy, value: range)
        }
    }

    private func plotted(_ raw: Double) -> Double {
        switch metric {
        case .duration: raw / 3600
        case .volume: unit.fromKg(raw)
        case .workouts: raw
        }
    }

    private func display(_ raw: Double) -> String {
        switch metric {
        case .duration: Format.duration(raw)
        case .volume: "\(unit.format(kg: raw)) \(unit.rawValue)"
        case .workouts: "\(Int(raw)) workout\(Int(raw) == 1 ? "" : "s")"
        }
    }
}
