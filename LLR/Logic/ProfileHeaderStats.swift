import Foundation

/// Numbers behind the Profile hero card, kept apart from the views so week edges and the
/// VoiceOver sentence can be unit tested with plain dates.
struct ProfileHeaderStats: Equatable {
    /// One flag per day of the current week, in the calendar's own week order (so the ring starts
    /// on the same weekday as the training calendar does).
    let weekDays: [Bool]
    let sessionCount: Int
    let streak: Int

    /// `starts` must hold every finished lift and run: the card's "Sessions" and the ring treat
    /// both alike, and the streak must agree with the calendar screen, which uses the same list.
    init(starts: [Date], now: Date = .now, calendar: Calendar = .current) {
        sessionCount = starts.count
        streak = TrainingCalendar.weekStreak(workouts: starts, now: now, calendar: calendar)
        weekDays = Self.days(of: starts, now: now, calendar: calendar)
    }

    var trainedDayCount: Int { weekDays.filter { $0 }.count }

    private static func days(of starts: [Date], now: Date, calendar: Calendar) -> [Bool] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return Array(repeating: false, count: 7)
        }
        let inWeek: [Date] = starts.filter { week.contains($0) }
        let trained: Set<Date> = Set(inWeek.map { calendar.startOfDay(for: $0) })
        var result: [Bool] = []
        for offset in 0..<7 {
            let day: Date? = calendar.date(byAdding: .day, value: offset, to: week.start)
            if let day {
                result.append(trained.contains(calendar.startOfDay(for: day)))
            } else {
                result.append(false)
            }
        }
        return result
    }

    /// The single sentence VoiceOver reads for the whole card. An unset name or goal is left out
    /// rather than spoken as a blank.
    static func spokenSummary(name: String, age: Int, height: String, heightUnit: String,
                              goal: String?, sessions: Int, streak: Int) -> String {
        var parts: [String] = []
        parts.append(name.isEmpty ? "Profile" : name)
        parts.append("\(age)")
        parts.append("\(height) \(heightUnit)")
        if let goal {
            parts.append("goal \(goal.lowercased())")
        }
        parts.append("\(sessions) \(sessions == 1 ? "session" : "sessions")")
        parts.append("\(streak) week streak")
        return parts.joined(separator: ", ")
    }
}
