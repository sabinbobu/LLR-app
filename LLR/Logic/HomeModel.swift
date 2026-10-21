import Foundation

/// What the Home tab shows, decided here so it can be unit tested without a view.
enum HomeModel {
    static let recentLimit = 5
    /// Collapsed workout cards preview this many exercises.
    static let previewCount = 3
    static let nextUpLookbackDays = 28

    struct Day: Identifiable, Equatable {
        enum State { case trained, today, rest, future }
        let date: Date
        let letter: String
        let number: Int
        let state: State
        var id: Date { date }
    }

    /// The seven days of the week containing `now`, in the calendar's own first-weekday order.
    /// A day with a workout reads as trained even when it is today.
    static func week(trained starts: [Date], now: Date = .now, calendar: Calendar = .current) -> [Day] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let today = calendar.startOfDay(for: now)
        let trainedDays = Set(starts.map { calendar.startOfDay(for: $0) })
        let letters = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).compactMap { offset in
            guard let raw = calendar.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            let day = calendar.startOfDay(for: raw)
            let state: Day.State =
                trainedDays.contains(day) ? .trained : day == today ? .today : day > today ? .future : .rest
            let weekday = calendar.component(.weekday, from: day)
            return Day(date: day, letter: letters[weekday - 1], number: calendar.component(.day, from: day), state: state)
        }
    }

    static func workoutCount(in starts: [Date], now: Date = .now, calendar: Calendar = .current) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return starts.filter { interval.contains($0) }.count
    }

    /// A repeat, never a generated workout: of the splits you did in the last four weeks, the one
    /// you did longest ago. Push, Pull, Legs done in that order points back at Push. Only named or
    /// categorised workouts count as a split, since an unnamed "Evening Workout" says nothing about
    /// what the day was.
    static func nextUp(_ workouts: [Workout], now: Date = .now, calendar: Calendar = .current) -> Workout? {
        let since = calendar.date(byAdding: .day, value: -nextUpLookbackDays, to: now) ?? .distantPast
        let candidates = workouts
            .filter { $0.endedAt != nil && $0.sectionRaw == "gym" && !$0.exercises.isEmpty && $0.startedAt >= since }
            .sorted { $0.startedAt > $1.startedAt }
        var seen = Set<String>()
        var lastOfEach: [Workout] = []
        for workout in candidates {
            guard let key = splitName(workout)?.lowercased(), seen.insert(key).inserted else { continue }
            lastOfEach.append(workout)
        }
        return lastOfEach.last
    }

    static func splitName(_ workout: Workout) -> String? {
        if !workout.name.isEmpty { return workout.name }
        return workout.category == .none ? nil : workout.category.title
    }
}
