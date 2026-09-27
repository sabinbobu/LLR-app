import SwiftUI

struct MuscleSplitView: View {
    let summaries: [WorkoutSummary]
    @State private var days = 30

    private var since: Date { Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast }
    private var split: [(group: String, sets: Int)] { Stats.muscleSplit(summaries, since: since) }
    private var radarValues: [MuscleGroup.RadarAxis: Int] { Stats.radarSplit(summaries, since: since) }

    var body: some View {
        let rows = split
        let most = max(rows.first?.sets ?? 1, 1)
        List {
            Picker("Range", selection: $days) {
                Text("7 days").tag(7)
                Text("30 days").tag(30)
                Text("90 days").tag(90)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)

            if !rows.isEmpty {
                RadarChart(values: radarValues)
                    .padding(.vertical, 12)
                    .listRowSeparator(.hidden)
            }

            if rows.isEmpty {
                Text("No working sets in this range").foregroundStyle(.secondary)
            }
            ForEach(rows, id: \.group) { row in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(row.group)
                        Spacer()
                        Text("\(row.sets) sets").monospacedDigit().foregroundStyle(.secondary)
                    }
                    GeometryReader { geo in
                        Capsule()
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * CGFloat(row.sets) / CGFloat(most))
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .animation(.snappy, value: days)
        .navigationTitle("Muscle Split")
    }
}
