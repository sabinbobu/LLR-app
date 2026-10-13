import SwiftUI

/// Totals across finished runs: count, distance, total and average time, and the hour you usually start.
struct RunSummaryCard: View {
    let runs: [Workout]

    private var totalKm: Double { runs.compactMap(\.distanceKm).reduce(0, +) }

    var body: some View {
        let summary = RunStats.summary(runs.compactMap { run in run.endedAt.map { (start: run.startedAt, end: $0) } })
        VStack(alignment: .leading, spacing: 12) {
            Label("Runs", systemImage: "figure.run").font(.headline)
            HStack(spacing: 18) {
                RunStat(label: "Runs", value: "\(summary.count)")
                if totalKm > 0 {
                    RunStat(label: "Distance", value: "\(totalKm.formatted(.number.precision(.fractionLength(0...1)))) km")
                }
                RunStat(label: "Total", value: Format.duration(summary.totalSeconds))
                RunStat(label: "Average", value: Format.duration(summary.averageSeconds))
                if let hour = summary.typicalHour {
                    RunStat(label: "Usual hour", value: RunStats.hourLabel(hour))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1.5))
    }
}
