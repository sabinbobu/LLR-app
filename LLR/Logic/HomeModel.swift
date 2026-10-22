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
    }

    struct Week: Equatable {
        let days: [WeekDay]
        let workoutCount: Int
    }

    /// `starts` is every finished lift and run, the same list the Profile ring reads, so the two
    /// never disagree about which days count.
    static func week(starts: [Date], now: Date = .now, calendar: Calendar = .current) -> Week {
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
                isFuture: calendar.startOfDay(for: date) > today
            ))
        }
        return Week(days: days, workoutCount: starts.filter { interval.contains($0) }.count)
    }
}
