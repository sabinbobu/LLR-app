import Foundation

struct SetValue: Equatable {
    var weightKg: Double
    var reps: Int
    var kind: SetKind = .normal
    /// Hold duration for a duration-based set (reps × seconds); nil = an ordinary weight/reps set.
    var durationSeconds: Int? = nil
}

struct Session: Equatable {
    var date: Date
    var sets: [SetValue]
}

enum OneRepMax {
    static func epley(weightKg: Double, reps: Int) -> Double {
        guard weightKg > 0, reps > 0 else { return 0 }
        // Epley inflates a single by 3.3%; a 1-rep set already is the max.
        return reps == 1 ? weightKg : weightKg * (1 + Double(reps) / 30)
    }

    static func epley(_ set: SetValue) -> Double { epley(weightKg: set.weightKg, reps: set.reps) }
}

enum PreviousPerformance {
    static func latestSets(in sessions: [Session]) -> [SetValue] {
        sessions.filter { !$0.sets.isEmpty }.max { $0.date < $1.date }?.sets ?? []
    }

    /// Same-position set from last time wins; past its end, repeat what was just logged today,
    /// since that reflects current fatigue better than last session's final set.
    static func prefill(index: Int, previous: [SetValue], currentLast: SetValue?) -> SetValue? {
        if index >= 0, index < previous.count { return previous[index] }
        // Extra sets are working sets: repeating a trailing warm-up/drop label would be wrong.
        guard var fallback = currentLast ?? previous.last else { return nil }
        fallback.kind = .normal
        return fallback
    }
}

enum ExerciseProgress {
    struct Point: Equatable {
        let date: Date
        let value: Double
    }

    static func bestSet(in sessions: [Session]) -> SetValue? {
        sessions.flatMap(\.sets)
            .filter { $0.kind.countsTowardProgress && OneRepMax.epley($0) > 0 }
            .max { a, b in
                let ea = OneRepMax.epley(a), eb = OneRepMax.epley(b)
                // Tolerance: 100×3 and 110×1 are equal on paper but differ in the last float bit.
                return abs(ea - eb) < 1e-6 ? a.weightKg < b.weightKg : ea < eb
            }
    }

    static func oneRepMaxSeries(_ sessions: [Session]) -> [Point] {
        series(sessions) { $0.map(OneRepMax.epley).max() ?? 0 }
    }

    static func heaviestWeightSeries(_ sessions: [Session]) -> [Point] {
        series(sessions) { $0.map(\.weightKg).max() ?? 0 }
    }

    private static func series(_ sessions: [Session], metric: ([SetValue]) -> Double) -> [Point] {
        sessions
            .map { Session(date: $0.date, sets: $0.sets.filter(\.kind.countsTowardProgress)) }
            .filter { !$0.sets.isEmpty }
            .sorted { $0.date < $1.date }
            .map { Point(date: $0.date, value: metric($0.sets)) }
    }
}
