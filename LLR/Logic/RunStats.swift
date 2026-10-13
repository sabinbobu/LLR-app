import Foundation

/// Runs track time only: how long, and at what hour of the day. No distance, pace or GPS.
enum RunStats {
    /// A run is a `Workout` with this section and no exercises, so it flows through the same
    /// timeline, calendar and streak as lifting without a new entity or any schema change.
    static let sectionRaw = "run"

    struct Summary: Equatable {
        var count: Int
        var totalSeconds: TimeInterval
        var averageSeconds: TimeInterval
        /// Most common start hour (0–23); the earliest hour wins a tie. Nil with no runs.
        var typicalHour: Int?
    }

    static func summary(_ runs: [(start: Date, end: Date)], calendar: Calendar = .current) -> Summary {
        let durations = runs.map { max($0.end.timeIntervalSince($0.start), 0) }
        let total = durations.reduce(0, +)
        var perHour: [Int: Int] = [:]
        for run in runs { perHour[calendar.component(.hour, from: run.start), default: 0] += 1 }
        let typical = perHour.max { a, b in a.value != b.value ? a.value < b.value : a.key > b.key }?.key
        return Summary(count: runs.count, totalSeconds: total, averageSeconds: runs.isEmpty ? 0 : total / Double(runs.count), typicalHour: typical)
    }

    /// "7 AM" style label for an hour of the day, in the user's locale.
    static func hourLabel(_ hour: Int, calendar: Calendar = .current) -> String {
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(.dateTime.hour())
    }
}
