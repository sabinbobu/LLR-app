import Foundation

/// What the Home screen shows, decided here so it can be tested without a view.
enum HomeModel {
    static let recentLimit = 3

    /// The gym routine to suggest next: the one whose last finished workout is oldest, never-done
    /// first. Workouts carry no routine id (and the schema stays as is), so "done" means a gym
    /// workout with the routine's name; an unmatched routine simply counts as never done.
    static func nextUp(routines: [Routine], workouts: [Workout]) -> Routine? {
        var lastDone: [String: Date] = [:]
        for workout in workouts where workout.endedAt != nil && workout.sectionRaw == "gym" && !workout.name.isEmpty {
            lastDone[workout.name] = max(lastDone[workout.name] ?? .distantPast, workout.startedAt)
        }
        // A routine with no exercises can't start, so suggesting it would dead-end the hero.
        let startable = routines.filter { $0.section == .gym && !$0.exercises.isEmpty }
        return startable.min { a, b in
            let (da, db) = (lastDone[a.name] ?? .distantPast, lastDone[b.name] ?? .distantPast)
            return da != db ? da < db : a.createdAt > b.createdAt
        }
    }

    struct WeekDay: Equatable {
        let letter: String
        let number: Int
        let trained: Bool
        let isToday: Bool
        let isFuture: Bool
        var category: SessionCategory = .none
    }

    struct Week: Equatable {
        let days: [WeekDay]
        let workoutCount: Int
    }

    /// `starts` is every finished lift and run, the same list the Profile ring reads, so the two
    /// never disagree about which days count.
    static func week(starts: [Date], categories: [Date: SessionCategory] = [:], now: Date = .now, calendar: Calendar = .current) -> Week {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return Week(days: [], workoutCount: 0)
        }
        let trained = ProfileHeaderStats(starts: starts, now: now, calendar: calendar).weekDays
        let today = calendar.startOfDay(for: now)
        var days: [WeekDay] = []
        for (offset, wasTrained) in trained.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            days.append(WeekDay(
                letter: calendar.veryShortWeekdaySymbols[weekday - 1],
                number: calendar.component(.day, from: date),
                trained: wasTrained,
                isToday: calendar.isDate(date, inSameDayAs: today),
                isFuture: calendar.startOfDay(for: date) > today,
                category: categories[calendar.startOfDay(for: date)] ?? .none
            ))
        }
        return Week(days: days, workoutCount: starts.filter { interval.contains($0) }.count)
    }

    // MARK: totals

    /// What a stats tile needs from one workout. Volume is walked off SwiftData, so callers hand in
    /// only the sessions of the range they show, not the whole history.
    struct Session {
        let start: Date
        let duration: TimeInterval
        let volumeKg: Double
    }

    struct Totals: Equatable {
        let count: Int
        let duration: TimeInterval
        let volumeKg: Double
    }

    static func totals(_ sessions: [Session]) -> Totals {
        Totals(count: sessions.count, duration: sessions.reduce(0) { $0 + $1.duration }, volumeKg: sessions.reduce(0) { $0 + $1.volumeKg })
    }

    /// The colour label for each day; the latest categorised workout of a day wins, like the calendar screen.
    static func categoryByDay(_ items: [(date: Date, category: SessionCategory)], calendar: Calendar = .current) -> [Date: SessionCategory] {
        var result: [Date: SessionCategory] = [:]
        for item in items.filter({ $0.category != .none }).sorted(by: { $0.date < $1.date }) {
            result[calendar.startOfDay(for: item.date)] = item.category
        }
        return result
    }

    // MARK: month

    /// Weekday initials starting on the calendar's first weekday, matching the week strip.
    static func weekdayLetters(calendar: Calendar = .current) -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    /// Leading `nil`s pad the grid so day 1 lands under its actual weekday.
    static func monthCells(month: Date, starts: [Date], categories: [Date: SessionCategory] = [:],
                           now: Date = .now, calendar: Calendar = .current) -> [WeekDay?] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let trained = TrainingCalendar.trainedDays(in: month, workouts: starts, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let leading = (calendar.component(.weekday, from: interval.start) - calendar.firstWeekday + 7) % 7
        var cells: [WeekDay?] = Array(repeating: nil, count: leading)
        var day = interval.start
        while day < interval.end {
            let start = calendar.startOfDay(for: day)
            cells.append(WeekDay(
                letter: "",
                number: calendar.component(.day, from: day),
                trained: trained.contains(start),
                isToday: start == today,
                isFuture: start > today,
                category: categories[start] ?? .none
            ))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return cells
    }
}
