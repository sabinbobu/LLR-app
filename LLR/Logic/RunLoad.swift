import Foundation

/// How much a run costs the body. A heuristic like `MuscleRecovery`, not physiology: it turns
/// speed into energy cost (MET), that into load (MET-hours), and spreads the load over the muscles
/// running uses. Every constant lives here so the whole model can be retuned in one place.
enum RunLoad {
    /// Running MET by speed, interpolated from the 2011 Compendium of Physical Activities
    /// (Ainsworth et al., Med Sci Sports Exerc 43(8):1575-81). UNVERIFIED: entered from memory.
    private static let compendiumMph: [(mph: Double, met: Double)] = [
        (4.0, 6.0), (5.0, 8.3), (5.2, 9.0), (6.0, 9.8), (6.7, 10.5), (7.0, 11.0),
        (7.5, 11.5), (8.0, 11.8), (8.6, 12.3), (9.0, 12.8), (10.0, 14.5), (11.0, 16.0),
    ]
    private static let kmhPerMph = 1.609344

    static let minPlausibleKmh = 3.0
    static let maxPlausibleKmh = 25.0
    /// MET-hours that read as 100% overall exhaustion: a half marathon lands near 85%.
    static let exhaustionMetHours = 24.0
    /// Overall exhaustion fades linearly to zero over this many hours.
    static let systemicRecoveryHours = 72.0
    /// Scales MET-hours into `MuscleRecovery` fatigue points (10 points reads 0% recovered).
    static let pointsPerMetHour = 0.8

    /// Share of the run's load each muscle takes. Legs carry it; core and lower back help stabilise.
    static let muscleWeights: [(muscle: MuscleGroup, weight: Double)] = [
        (.quadriceps, 1.0), (.calves, 1.0), (.hamstrings, 0.8), (.glutes, 0.8),
        (.abdominals, 0.3), (.lowerBack, 0.3),
    ]

    struct MuscleLoad: Equatable {
        let muscle: MuscleGroup
        let points: Double
        /// Recovery lost from fresh, on `MuscleRecovery`'s scale (10 points = 100%).
        var percentDrop: Double { min(100, points * 10) }
    }

    static func speedKmh(km: Double, seconds: Double) -> Double {
        seconds > 0 ? km / (seconds / 3600) : 0
    }

    static func paceSecondsPerKm(km: Double, seconds: Double) -> Double {
        km > 0 ? seconds / km : 0
    }

    static func isPlausible(km: Double, seconds: Double) -> Bool {
        guard km > 0, seconds > 0 else { return false }
        let speed = speedKmh(km: km, seconds: seconds)
        return speed >= minPlausibleKmh && speed <= maxPlausibleKmh
    }

    /// Clamped to the table's ends: a slow jog costs at least a 4 mph run, nobody outruns 11 mph here.
    static func met(atKmh speed: Double) -> Double {
        let table = compendiumMph.map { (kmh: $0.mph * kmhPerMph, met: $0.met) }
        guard let first = table.first, let last = table.last else { return 0 }
        if speed <= first.kmh { return first.met }
        if speed >= last.kmh { return last.met }
        for index in 1..<table.count where speed <= table[index].kmh {
            let low = table[index - 1], high = table[index]
            let fraction = (speed - low.kmh) / (high.kmh - low.kmh)
            return low.met + fraction * (high.met - low.met)
        }
        return last.met
    }

    static func metHours(km: Double, seconds: Double) -> Double {
        guard seconds > 0 else { return 0 }
        return met(atKmh: speedKmh(km: km, seconds: seconds)) * seconds / 3600
    }

    /// 0–100 at the end of the run.
    static func overallExhaustionPercent(metHours: Double) -> Double {
        min(100, max(0, 100 * metHours / exhaustionMetHours))
    }

    /// What is left of that exhaustion `hours` later.
    static func remainingExhaustion(_ percent: Double, hoursSince hours: Double) -> Double {
        guard hours >= 0 else { return percent }
        return max(0, percent * (1 - hours / systemicRecoveryHours))
    }

    static func muscleLoads(metHours: Double) -> [MuscleLoad] {
        muscleWeights.map { MuscleLoad(muscle: $0.muscle, points: $0.weight * pointsPerMetHour * metHours) }
    }

    /// "5:30" for 330 s/km.
    static func paceLabel(secondsPerKm: Double) -> String {
        let total = Int(secondsPerKm.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
