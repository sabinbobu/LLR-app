import Foundation

/// GitHub-style year grid: one column per week, one cell per day, shaded by time or volume.
/// Pure date math so it can be unit tested without SwiftData.
enum ActivityHeatmap {
    enum Metric: String, CaseIterable, Identifiable {
        case time = "Time", volume = "Volume"
        var id: String { rawValue }
    }

    struct Session {
        let date: Date
        let minutes: Int
        let volumeKg: Double
    }

    struct Cell: Equatable {
        let day: Date
        /// 0 = no workout, 1...4 = lightest to heaviest.
        let level: Int
        let isFuture: Bool
    }

    /// 53 week-columns ending with the current week, so a year is always fully visible.
    static let weekCount = 53

    static func columns(
        sessions: [Session], metric: Metric, now: Date = .now, calendar: Calendar = .current
    ) -> [[Cell]] {
        let today = calendar.startOfDay(for: now)
        let offset = (calendar.component(.weekday, from: today) - calendar.firstWeekday + 7) % 7
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -offset, to: today),
              let start = calendar.date(byAdding: .weekOfYear, value: -(weekCount - 1), to: currentWeekStart)
        else { return [] }

        var perDay: [Date: (minutes: Int, volume: Double)] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            let current = perDay[day] ?? (0, 0)
            perDay[day] = (current.minutes + max(0, session.minutes), current.volume + max(0, session.volumeKg))
        }
        func value(_ day: Date) -> Double? {
            guard let entry = perDay[day] else { return nil }
            return metric == .time ? Double(entry.minutes) : entry.volume
        }

        // Quartiles of the non-zero days, so shading is relative to your own history.
        let positives = perDay.keys.compactMap(value).filter { $0 > 0 }.sorted()
        func quartile(_ p: Double) -> Double {
            positives.isEmpty ? 0 : positives[min(positives.count - 1, Int(p * Double(positives.count)))]
        }
        let (q1, q2, q3) = (quartile(0.25), quartile(0.5), quartile(0.75))

        return (0..<weekCount).map { week in
            (0..<7).compactMap { weekday in
                guard let day = calendar.date(byAdding: .day, value: week * 7 + weekday, to: start) else { return nil }
                let level: Int
                if let v = value(day) {
                    level = v <= 0 ? 1 : v >= q3 ? 4 : v >= q2 ? 3 : v >= q1 ? 2 : 1
                } else {
                    level = 0
                }
                return Cell(day: day, level: level, isFuture: day > today)
            }
        }
    }
}
