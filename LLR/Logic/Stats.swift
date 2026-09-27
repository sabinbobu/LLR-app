import Foundation

struct WorkoutSummary: Equatable {
    var date: Date
    var duration: TimeInterval
    var volumeKg: Double
    var reps: Int
    /// Working sets per muscle group.
    var muscleSets: [String: Int]
}

enum Stats {
    enum Metric: String, CaseIterable, Identifiable {
        case duration = "Duration"
        case volume = "Volume"
        case workouts = "Workouts"

        var id: String { rawValue }
    }

    /// How far back `weekly` looks. `.all` needs the date of the first workout to know how many
    /// weeks that actually is; callers without one yet (no history) fall back to a single week.
    enum Range: String, CaseIterable, Identifiable {
        case threeMonths = "3M", sixMonths = "6M", year = "Year", all = "All"
        var id: String { rawValue }

        func weeks(since firstWorkoutDate: Date?, now: Date = .now, calendar: Calendar = .current) -> Int {
            switch self {
            case .threeMonths: return 13
            case .sixMonths: return 26
            case .year: return 52
            case .all: break
            }
            guard let firstWorkoutDate,
                  let start = calendar.dateInterval(of: .weekOfYear, for: firstWorkoutDate)?.start,
                  let current = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
                  let weeksBetween = calendar.dateComponents([.weekOfYear], from: start, to: current).weekOfYear
            else { return 1 }
            return max(1, weeksBetween + 1)
        }
    }

    struct WeekPoint: Equatable, Identifiable {
        let weekStart: Date
        let value: Double
        var id: Date { weekStart }
    }

    /// Always returns `weeks` points, oldest first, zero-filled — a missed week must show as a gap,
    /// not vanish, or the chart lies about consistency.
    static func weekly(
        _ workouts: [WorkoutSummary],
        metric: Metric,
        weeks: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [WeekPoint] {
        guard weeks > 0, let current = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        let starts: [Date] = (0..<weeks).reversed().compactMap {
            calendar.date(byAdding: .weekOfYear, value: -$0, to: current)
        }
        var totals: [Date: Double] = [:]
        for workout in workouts {
            guard let week = calendar.dateInterval(of: .weekOfYear, for: workout.date)?.start else { continue }
            totals[week, default: 0] += value(of: workout, metric)
        }
        return starts.map { WeekPoint(weekStart: $0, value: totals[$0] ?? 0) }
    }

    static func muscleSplit(_ workouts: [WorkoutSummary], since: Date) -> [(group: String, sets: Int)] {
        var totals: [String: Int] = [:]
        for workout in workouts where workout.date >= since {
            totals.merge(workout.muscleSets, uniquingKeysWith: +)
        }
        return totals
            .map { (group: $0.key, sets: $0.value) }
            .sorted { $0.sets == $1.sets ? $0.group < $1.group : $0.sets > $1.sets }
    }

    /// The same primary-muscle sets as `muscleSplit`, regrouped onto the radar's 12 coarser axes.
    static func radarSplit(_ workouts: [WorkoutSummary], since: Date) -> [MuscleGroup.RadarAxis: Int] {
        var totals: [MuscleGroup.RadarAxis: Int] = [:]
        for (group, sets) in muscleSplit(workouts, since: since) {
            guard let muscle = MuscleGroup(rawValue: group), let axis = muscle.radarAxis else { continue }
            totals[axis, default: 0] += sets
        }
        return totals
    }

    private static func value(of workout: WorkoutSummary, _ metric: Metric) -> Double {
        switch metric {
        case .duration: workout.duration
        case .volume: workout.volumeKg
        case .workouts: 1
        }
    }
}
