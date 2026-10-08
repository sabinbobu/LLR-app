import Foundation

struct SetValue: Equatable {
    var weightKg: Double
    var reps: Int
    var kind: SetKind = .normal
    /// Hold duration for a duration-based set (reps × seconds); nil = an ordinary weight/reps set.
    var durationSeconds: Int? = nil
    /// Reps in reserve; nil = not rated. Never prefilled: a set that hasn't happened has no effort yet.
    var rir: Double? = nil
}

struct Session: Equatable {
    var date: Date
    var sets: [SetValue]
}

enum OneRepMax {
    /// The usual submaximal estimators. They agree closely at low reps and drift apart as reps rise.
    enum Formula: String, CaseIterable, Identifiable {
        case epley, brzycki, lombardi

        var id: String { rawValue }
        var title: String { rawValue.capitalized }

        /// For code outside views, which can't use @AppStorage.
        static var stored: Formula {
            UserDefaults.standard.string(forKey: StorageKey.oneRepMaxFormula).flatMap(Formula.init(rawValue:)) ?? .epley
        }
    }

    /// Past this many reps a set says more about work capacity than about maximal strength, and
    /// the formulas disagree by double digits: no estimate beats a made-up one.
    static let repCap = 12

    static func epley(weightKg: Double, reps: Int) -> Double {
        guard weightKg > 0, reps > 0 else { return 0 }
        // Epley inflates a single by 3.3%; a 1-rep set already is the max.
        return reps == 1 ? weightKg : weightKg * (1 + Double(reps) / 30)
    }

    /// 0 when there is nothing honest to say: no load, no reps, or more reps than `repCap`.
    static func estimate(weightKg: Double, reps: Int, formula: Formula = .stored) -> Double {
        guard weightKg > 0, reps > 0, reps <= repCap else { return 0 }
        guard reps > 1 else { return weightKg }
        switch formula {
        case .epley: return epley(weightKg: weightKg, reps: reps)
        case .brzycki: return weightKg * 36 / (37 - Double(reps))
        case .lombardi: return weightKg * pow(Double(reps), 0.1)
        }
    }

    static func estimate(_ set: SetValue, formula: Formula = .stored) -> Double {
        estimate(weightKg: set.weightKg, reps: set.reps, formula: formula)
    }
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

    static func bestSet(in sessions: [Session], formula: OneRepMax.Formula = .stored) -> SetValue? {
        let sets = sessions.flatMap(\.sets).filter { $0.kind.countsTowardProgress && $0.weightKg > 0 && $0.reps > 0 }
        let estimable = sets.filter { OneRepMax.estimate($0, formula: formula) > 0 }
        // Only high-rep work logged: nothing to rank an estimate by, so the heaviest set stands in.
        guard !estimable.isEmpty else { return sets.max { ($0.weightKg, $0.reps) < ($1.weightKg, $1.reps) } }
        return estimable.max { a, b in
            let ea = OneRepMax.estimate(a, formula: formula), eb = OneRepMax.estimate(b, formula: formula)
            // Tolerance: 100×3 and 110×1 are equal on paper but differ in the last float bit.
            return abs(ea - eb) < 1e-6 ? a.weightKg < b.weightKg : ea < eb
        }
    }

    /// A session with no set inside the rep cap has no estimate and is left off the chart.
    static func oneRepMaxSeries(_ sessions: [Session], formula: OneRepMax.Formula = .stored) -> [Point] {
        points(sessions) { $0.map { OneRepMax.estimate($0, formula: formula) }.filter { $0 > 0 }.max() }
    }

    static func heaviestWeightSeries(_ sessions: [Session]) -> [Point] {
        points(sessions) { $0.map(\.weightKg).max() }
    }

    /// Oldest first, working sets only. A session `value` has nothing to say about is left out
    /// rather than plotted as zero.
    static func points(_ sessions: [Session], value: ([SetValue]) -> Double?) -> [Point] {
        working(sessions)
            .sorted { $0.date < $1.date }
            .compactMap { session in value(session.sets).map { Point(date: session.date, value: $0) } }
    }

    static func working(_ sessions: [Session]) -> [Session] {
        sessions
            .map { Session(date: $0.date, sets: $0.sets.filter(\.kind.countsTowardProgress)) }
            .filter { !$0.sets.isEmpty }
    }
}
