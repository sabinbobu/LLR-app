import SwiftUI

/// A year of training at a glance, newest week on the right. Shading is relative to your own
/// busiest days, so it reads the same whether you train twice a week or six times.
struct ActivityHeatmapView: View {
    let workouts: [Workout]
    @State private var metric: ActivityHeatmap.Metric = .time

    private let cell: CGFloat = 13
    private let gap: CGFloat = 3

    private var columns: [[ActivityHeatmap.Cell]] {
        ActivityHeatmap.columns(
            sessions: workouts.map {
                ActivityHeatmap.Session(date: $0.startedAt, minutes: Int($0.duration / 60), volumeKg: $0.volumeKg)
            },
            metric: metric
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Shade by", selection: $metric) {
                ForEach(ActivityHeatmap.Metric.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: gap) {
                        ForEach(Array(columns.enumerated()), id: \.offset) { index, week in
                            VStack(spacing: gap) {
                                ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(color(day))
                                        .frame(width: cell, height: cell)
                                }
                            }
                            .id(index)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onAppear { proxy.scrollTo(ActivityHeatmap.weekCount - 1, anchor: .trailing) }
            }

            HStack(spacing: 4) {
                Text(metric == .time ? "Less time" : "Less volume")
                ForEach(0...4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3).fill(shade(level)).frame(width: cell, height: cell)
                }
                Text(metric == .time ? "More time" : "More volume")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Activity heatmap, \(workouts.count) workouts")
    }

    private func color(_ day: ActivityHeatmap.Cell) -> Color {
        day.isFuture ? .clear : shade(day.level)
    }

    private func shade(_ level: Int) -> Color {
        level == 0 ? Color(.systemGray5) : Theme.accent.opacity(0.25 + 0.2 * Double(level))
    }
}
