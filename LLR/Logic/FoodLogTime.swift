import Foundation

/// When a food entry belongs, and which day it falls on. Pure so the rules around past days are tested.
enum FoodLogTime {
    /// Today logs "now"; a past day gets midday, a neutral time that cannot spill into the day next to it.
    static func defaultTime(for day: Date, now: Date = .now, calendar: Calendar = .current) -> Date {
        if calendar.isDate(day, inSameDayAs: now) { return now }
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }

    /// Start of `day` and of the next day: an entry belongs to the day when `start <= loggedAt < end`.
    static func dayBounds(_ day: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }

    /// Food cannot be logged in the future: nothing has been eaten yet.
    static func clamped(_ date: Date, now: Date = .now) -> Date { min(date, now) }
}
