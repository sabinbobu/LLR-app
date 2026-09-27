import Foundation

/// Scale weight swings day to day with water and gut contents; the trend is what actually moves.
///
/// - Gaps between weigh-ins are filled by linear interpolation before smoothing, as MacroFactor does,
///   so a skipped week doesn't make the next weigh-in count for more than it should.
/// - Smoothing is Walker's 10% exponentially smoothed moving average (The Hacker's Diet): each day
///   the trend moves a tenth of the way toward that day's weight.
enum WeightTrend {
    struct Point: Equatable {
        let date: Date
        /// The actual weigh-in that day, nil on an interpolated day.
        let raw: Double?
        let trend: Double
    }

    static let smoothing = 0.1

    static func points(_ weighIns: [(date: Date, kg: Double)], calendar: Calendar = .current) -> [Point] {
        // Several weigh-ins in a day keep the earliest: morning, pre-meal weight is the convention.
        var byDay: [Date: (date: Date, kg: Double)] = [:]
        for weighIn in weighIns {
            let day = calendar.startOfDay(for: weighIn.date)
            if let existing = byDay[day], existing.date <= weighIn.date { continue }
            byDay[day] = weighIn
        }
        let days = byDay.keys.sorted()
        guard let first = days.first, let last = days.last else { return [] }

        var result: [Point] = []
        var trend = byDay[first]!.kg
        var previousLogged = (day: first, kg: trend)
        var nextIndex = 1
        var day = first
        while day <= last {
            let raw = byDay[day]?.kg
            let weight: Double
            if let raw {
                weight = raw
                previousLogged = (day, raw)
                if day != first { nextIndex += 1 }
            } else {
                let next = days[nextIndex]
                let span = Double(calendar.dateComponents([.day], from: previousLogged.day, to: next).day ?? 1)
                let offset = Double(calendar.dateComponents([.day], from: previousLogged.day, to: day).day ?? 0)
                weight = previousLogged.kg + (byDay[next]!.kg - previousLogged.kg) * offset / span
            }
            if day != first { trend += smoothing * (weight - trend) }
            result.append(Point(date: day, raw: raw, trend: trend))
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = tomorrow
        }
        return result
    }

    /// Least-squares slope of the trend over the last `days`, per week. Nil until there are two days.
    static func weeklyRate(_ points: [Point], days: Int = 14) -> Double? {
        let recent = points.suffix(days)
        guard recent.count >= 2 else { return nil }
        let n = Double(recent.count)
        let xs = (0..<recent.count).map(Double.init)
        let ys = recent.map(\.trend)
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        let numerator = zip(xs, ys).reduce(0) { $0 + ($1.0 - meanX) * ($1.1 - meanY) }
        let denominator = xs.reduce(0) { $0 + ($1 - meanX) * ($1 - meanX) }
        return denominator > 0 ? numerator / denominator * 7 : nil
    }

    /// Trend change from the first point on or after `since` to the latest.
    static func change(_ points: [Point], since: Date) -> Double? {
        guard let last = points.last, let start = points.first(where: { $0.date >= since }), start != last else { return nil }
        return last.trend - start.trend
    }

    /// The trend on a given day, clamped to the ends of the series.
    static func trend(on date: Date, in points: [Point], calendar: Calendar = .current) -> Double? {
        let day = calendar.startOfDay(for: date)
        if let first = points.first, day < first.date { return first.trend }
        return points.last(where: { $0.date <= day })?.trend
    }
}
