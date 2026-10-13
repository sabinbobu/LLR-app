import SwiftUI

/// Totals across finished runs: count, total and average time, and the hour you usually start.
struct RunSummaryCard: View {
    let runs: [Workout]

    var body: some View {
        let summary = RunStats.summary(runs.compactMap { run in run.endedAt.map { (start: run.startedAt, end: $0) } })
        VStack(alignment: .leading, spacing: 12) {
            Label("Runs", systemImage: "figure.run").font(.headline)
            HStack(spacing: 28) {
                RunStat(label: "Runs", value: "\(summary.count)")
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
