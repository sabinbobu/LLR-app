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
        case reps = "Reps"

        var id: String { rawValue }
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

    private static func value(of workout: WorkoutSummary, _ metric: Metric) -> Double {
        switch metric {
        case .duration: workout.duration
        case .volume: workout.volumeKg
        case .reps: Double(workout.reps)
        }
    }
}
