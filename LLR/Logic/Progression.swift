import Foundation

/// Double progression inside a rep range the lifter picks per exercise. Below the top of the range,
/// each working set aims for one more rep at the same weight; once every working set reached the
/// top last time, the load goes up by the smallest step and reps restart at the bottom.
/// Warm-up and drop sets aren't progressed: they're prescribed relative to the working sets.
enum Progression {
    static let presets: [ClosedRange<Int>] = [3...5, 5...8, 6...10, 8...12, 10...15, 12...20]

    enum Plan: Equatable {
        case addLoad(kg: Double)
        case addReps
    }

    static func isProgressed(_ set: SetValue) -> Bool {
        set.kind == .normal || set.kind == .failure
    }

    static func plan(previous: [SetValue], range: ClosedRange<Int>, incrementKg: Double) -> Plan? {
        let working = previous.filter(isProgressed)
        guard !working.isEmpty else { return nil }
        let loadUp = working.allSatisfy { $0.reps >= range.upperBound && $0.weightKg > 0 }
        return loadUp ? .addLoad(kg: incrementKg) : .addReps
    }

    /// Last session's sets rewritten as this session's targets; nil when there's nothing to build on.
    static func targets(previous: [SetValue], range: ClosedRange<Int>, incrementKg: Double) -> [SetValue]? {
        guard let plan = plan(previous: previous, range: range, incrementKg: incrementKg) else { return nil }
        return previous.map { set in
            guard isProgressed(set) else { return set }
            var next = set
            switch plan {
            case .addLoad(let kg):
                next.weightKg += kg
                next.reps = range.lowerBound
            case .addReps where set.weightKg == 0:
                // Bodyweight: reps are the only lever, so the range doesn't cap them.
                next.reps += 1
            case .addReps:
                // A set already past the top keeps what it did rather than being asked for less.
                next.reps = max(set.reps, min(set.reps + 1, range.upperBound))
            }
            return next
        }
    }

    static func prefill(
        index: Int,
        previous: [SetValue],
        currentLast: SetValue?,
        range: ClosedRange<Int>?,
        incrementKg: Double
    ) -> SetValue? {
        let base = range.flatMap { targets(previous: previous, range: $0, incrementKg: incrementKg) } ?? previous
        return PreviousPerformance.prefill(index: index, previous: base, currentLast: currentLast)
    }

    /// The smallest jump a typical gym offers for that kit.
    static func incrementKg(equipment: [String], unit: WeightUnit) -> Double {
        let kettlebell = equipment.contains("Kettlebell")
        let dumbbell = equipment.contains("Dumbbell")
        switch unit {
        case .kg: return kettlebell ? 4 : dumbbell ? 2 : 2.5
        case .lbs: return (kettlebell ? 10 : 5) * WeightUnit.kgPerLb
        }
    }
}
