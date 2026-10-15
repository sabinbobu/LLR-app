import SwiftUI
import WidgetKit

struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: TrainingSnapshot?
}

struct StreakTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, snapshot: TrainingSnapshot(streak: 3, trainedDaysThisMonth: [], generatedAt: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: .now, snapshot: TrainingSnapshot.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(date: .now, snapshot: TrainingSnapshot.read())
        // The app resyncs after every Finish and on backgrounding; this is just a slow fallback.
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(21_600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct StreakWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StreakEntry

    var body: some View {
        switch family {
        case .systemMedium: mediumBody
        default: smallBody
        }
    }

    private var streak: Int { entry.snapshot?.streak(asOf: entry.date) ?? 0 }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "flame.fill").foregroundStyle(.orange)
            Text("\(streak)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(streak == 1 ? "week streak" : "week streak")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumBody: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(streak)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("week streak").font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            monthGrid
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
            ForEach(daysInCurrentMonth(), id: \.self) { day in
                Circle()
                    .fill(isTrained(day) ? Color.llrAccent : Color.gray.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func isTrained(_ day: Date) -> Bool {
        guard let snapshot = entry.snapshot else { return false }
        let calendar = Calendar.current
        return snapshot.trainedDaysThisMonth.contains { calendar.isDate($0, inSameDayAs: day) }
    }

    private func daysInCurrentMonth() -> [Date] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: .now) else { return [] }
        var days: [Date] = []
        var day = interval.start
        while day < interval.end {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Training Streak")
        .description("Your weekly training streak and this month's workouts at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
