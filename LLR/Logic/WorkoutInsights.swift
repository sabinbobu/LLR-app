import Foundation

/// A finished workout read against what came before: its totals against the last workout of the
/// same name, and each lift's best estimate against that lift's previous session. Arithmetic on
/// the log only, no coaching.
enum WorkoutInsights {
    struct Totals: Equatable {
        var volumeKg: Double
        /// Working sets; warm-ups left out.
        var sets: Int
        var duration: TimeInterval
    }

    struct Comparison: Equatable {
        let volumeDeltaKg: Double
        /// nil when the earlier workout moved no load, so there is nothing to take a share of.
        let volumePercent: Double?
        let setDelta: Int
        let durationDelta: TimeInterval
    }

    struct Lift: Equatable {
        var name: String
        var sets: [SetValue]
        /// The same exercise's sets the last time it was done; empty the first time.
        var previous: [SetValue]
    }

    struct Change: Equatable, Identifiable {
        let name: String
        let best: SetValue
        let estimateKg: Double
        /// nil = no earlier session with an estimate to hold this one against.
        let deltaKg: Double?

        var id: String { name }
    }

    static func compare(_ now: Totals, to then: Totals) -> Comparison {
        let delta = now.volumeKg - then.volumeKg
        return Comparison(
            volumeDeltaKg: delta,
            volumePercent: then.volumeKg > 0 ? delta / then.volumeKg * 100 : nil,
            setDelta: now.sets - then.sets,
            durationDelta: now.duration - then.duration
        )
    }

    /// One line per lift that has an estimate, in workout order. Bodyweight, hold and high-rep
    /// work has no one-rep max to compare, so it is left out rather than shown as zero.
    static func changes(_ lifts: [Lift], formula: OneRepMax.Formula = .stored) -> [Change] {
        var merged: [Lift] = []
        for lift in lifts {
            // The same exercise added twice is still one lift on the day.
            if let index = merged.firstIndex(where: { $0.name == lift.name }) {
                merged[index].sets += lift.sets
            } else {
                merged.append(lift)
            }
        }
        func best(_ sets: [SetValue]) -> (set: SetValue, kg: Double)? {
            sets.filter(\.kind.countsTowardProgress)
                .map { ($0, OneRepMax.estimate($0, formula: formula)) }
                .filter { $0.1 > 0 }
                .max { $0.1 < $1.1 }
                .map { (set: $0.0, kg: $0.1) }
        }
        return merged.compactMap { lift in
            guard let now = best(lift.sets) else { return nil }
            let delta = best(lift.previous).map { now.kg - $0.kg }
            // Float noise on an identical set must read as no change, not as a hair up or down.
            return Change(name: lift.name, best: now.set, estimateKg: now.kg, deltaKg: delta.map { abs($0) < 1e-6 ? 0 : $0 })
        }
    }
}
