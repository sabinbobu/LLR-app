import Foundation

/// Effort read across many sets. Everything aggregates in reps in reserve and is converted for
/// display, so a history that mixes RIR and RPE still draws one series.
enum EffortStats {
    /// Below this many rated sets an average is noise: one tap would read like a finding.
    static let minRated = 5
    /// The last histogram bucket collects everything from here up ("4+").
    static let tail = 4

    /// One completed working set; `rir` is nil when it was never rated.
    struct Sample: Equatable {
        let date: Date
        let rir: Double?
    }

    struct Summary: Equatable {
        let done: Int
        let rated: Int
        let hard: Int
        /// nil until `minRated` sets are rated.
        let averageRir: Double?
        let hardShare: Double?
    }

    /// Rating is optional, so partial coverage is the normal case: `done` rides along as the
    /// denominator an average would otherwise hide.
    static func summary(_ samples: [Sample]) -> Summary {
        let ratings = samples.compactMap(\.rir)
        let hard = ratings.filter { Effort.isHard($0) }.count
        let enough = ratings.count >= minRated
        return Summary(
            done: samples.count,
            rated: ratings.count,
            hard: hard,
            averageRir: enough ? ratings.reduce(0, +) / Double(ratings.count) : nil,
            hardShare: enough ? Double(hard) / Double(ratings.count) : nil
        )
    }

    struct Week: Equatable, Identifiable {
        let weekStart: Date
        let averageRir: Double
        let rated: Int
        /// Every working set that week, rated or not. Effort climbing with volume is fatigue piling
        /// up; volume climbing with effort flat is the adaptation being trained for.
        let sets: Int
        var id: Date { weekStart }
    }

    /// Oldest first. A week with a single rated set is dropped rather than drawn, so one tap
    /// never becomes a peak in the curve.
    static func weeks(_ samples: [Sample], calendar: Calendar = .current) -> [Week] {
        var byWeek: [Date: (sum: Double, rated: Int, sets: Int)] = [:]
        for sample in samples {
            guard let start = calendar.dateInterval(of: .weekOfYear, for: sample.date)?.start else { continue }
            var week = byWeek[start] ?? (0, 0, 0)
            week.sets += 1
            if let rir = sample.rir {
                week.sum += rir
                week.rated += 1
            }
            byWeek[start] = week
        }
        return byWeek
            .filter { $0.value.rated >= 2 }
            .map { Week(weekStart: $0.key, averageRir: $0.value.sum / Double($0.value.rated), rated: $0.value.rated, sets: $0.value.sets) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    struct Bucket: Equatable, Identifiable {
        /// Whole reps in reserve, hardest first; `tail` stands for itself and everything easier.
        let rir: Int
        let count: Int
        let share: Double
        var id: Int { rir }
        var isTail: Bool { rir == EffortStats.tail }
    }

    /// Always one bucket per step, empty ones included. An average alone hides the spread: half
    /// the sets at 0 and half at 4 average to a healthy-looking 2.
    static func histogram(_ samples: [Sample]) -> [Bucket] {
        let ratings = samples.compactMap(\.rir)
        var counts = Array(repeating: 0, count: tail + 1)
        for rir in ratings {
            counts[min(tail, max(0, Int(rir.rounded(.down))))] += 1
        }
        return counts.enumerated().map { index, count in
            Bucket(rir: index, count: count, share: ratings.isEmpty ? 0 : Double(count) / Double(ratings.count))
        }
    }
}
