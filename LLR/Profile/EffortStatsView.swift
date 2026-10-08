import Charts
import SwiftUI

/// How close to failure the training runs: an average, how much of it was hard, the trend, the spread.
struct EffortStatsView: View {
    let samples: [EffortStats.Sample]
    @AppStorage(StorageKey.effortScale) private var effortScale: EffortScale = .off
    @State private var days = 90

    /// Ratings are stored as RIR, so that is the fallback if the column was switched off meanwhile.
    private var scale: EffortScale { effortScale == .off ? .rir : effortScale }

    private var inRange: [EffortStats.Sample] {
        guard days > 0, let since = Calendar.current.date(byAdding: .day, value: -days, to: .now) else { return samples }
        return samples.filter { $0.date >= since }
    }

    private var hardRule: String { "\(scale.title) \(Effort.text(rir: Effort.hardRir, scale: scale)) or harder" }

    var body: some View {
        let samples = inRange
        let summary = EffortStats.summary(samples)
        let weeks = EffortStats.weeks(samples)
        let buckets = EffortStats.histogram(samples)
        List {
            Picker("Range", selection: $days) {
                Text("30 days").tag(30)
                Text("90 days").tag(90)
                Text("Year").tag(365)
                Text("All").tag(0)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)

            if summary.rated == 0 {
                Text("No rated sets in this period").foregroundStyle(.secondary)
            } else {
                headline(summary)
                // Notes are rows, not section footers: a plain list draws a footer at body size.
                if weeks.count > 1 {
                    Section("Week by week") {
                        chart(weeks)
                        note("Higher on the chart is harder.")
                    }
                }
                Section("Where the sets land") {
                    let most = max(buckets.map(\.count).max() ?? 1, 1)
                    ForEach(buckets) { bucketRow($0, most: most) }
                    note("Most working sets belong close to failure, not at it. An average hides the spread: half at the floor and half at the top still reads as a healthy middle.")
                }
            }
        }
        .listStyle(.plain)
        .animation(.snappy, value: days)
        .navigationTitle("Effort")
    }

    private func headline(_ summary: EffortStats.Summary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.averageRir.map { "\(scale.title) \(Effort.text(rir: $0, scale: scale))" } ?? "–")
                        .font(.title.bold())
                    Text("average effort").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(summary.hardShare.map { "\(Int(($0 * 100).rounded()))%" } ?? "–")
                        .font(.title.bold())
                        .foregroundStyle(Theme.accent)
                    Text("at \(hardRule)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .monospacedDigit()
            Text(summary.averageRir == nil
                ? "\(summary.rated) of \(summary.done) working sets rated. Averages appear after \(EffortStats.minRated)."
                : "\(summary.rated) of \(summary.done) working sets rated")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .listRowSeparator(.hidden)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .listRowSeparator(.hidden)
    }

    private func value(_ rir: Double) -> Double { scale == .rpe ? 10 - rir : rir }

    private func chart(_ weeks: [EffortStats.Week]) -> some View {
        Chart(weeks) { week in
            LineMark(x: .value("Week", week.weekStart), y: .value(scale.title, value(week.averageRir)))
            PointMark(x: .value("Week", week.weekStart), y: .value(scale.title, value(week.averageRir)))
        }
        // Fewer reps in reserve is harder, so the RIR axis runs downwards to keep "up" meaning harder.
        .chartYScale(domain: .automatic(includesZero: false, reversed: scale == .rir))
        .foregroundStyle(Theme.accent)
        .frame(height: 160)
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
    }

    /// Buckets run hardest first in both scales: RIR 0 and RPE 10 are the same set.
    private func label(_ bucket: EffortStats.Bucket) -> String {
        if scale == .rpe { return bucket.isTail ? "RPE 6 or less" : "RPE \(10 - bucket.rir)" }
        return bucket.isTail ? "RIR \(bucket.rir)+" : "RIR \(bucket.rir)"
    }

    private func bucketRow(_ bucket: EffortStats.Bucket, most: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label(bucket))
                Spacer()
                Text(bucket.count == 0 ? "–" : "\(bucket.count) · \(Int((bucket.share * 100).rounded()))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                Capsule()
                    .fill(Effort.isHard(Double(bucket.rir)) ? Theme.accent : Color(.systemGray3))
                    .frame(width: geo.size.width * CGFloat(bucket.count) / CGFloat(most))
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}
