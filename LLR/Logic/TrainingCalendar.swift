import Foundation

/// Pure date math behind the training calendar and its streak, kept independent of SwiftData so it
/// can be unit tested against plain `Date` values.
enum TrainingCalendar {
    /// Every day within `month` that has at least one workout starting on it.
    static func trainedDays(in month: Date, workouts: [Date], calendar: Calendar = .current) -> Set<Date> {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        return Set(workouts.filter { interval.contains($0) }.map { calendar.startOfDay(for: $0) })
    }

    /// Consecutive weeks with at least one workout, counting back from the current week. The
    /// current week doesn't break the streak just for not being trained *yet* — it's not over.
    static func weekStreak(workouts: [Date], now: Date = .now, calendar: Calendar = .current) -> Int {
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        let trainedWeeks = Set(workouts.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0)?.start })

        var streak = trainedWeeks.contains(currentWeekStart) ? 1 : 0
        var week = currentWeekStart
        while let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: week) {
            week = previous
            guard trainedWeeks.contains(week) else { break }
            streak += 1
        }
        return streak
    }
}
