import Foundation

/// What the next session should aim for, derived from the log every time it is asked: nothing is
/// stored, so fixing a mistyped set fixes the target too.
///
/// - Double: climb a rep range at one weight; every working set at the top adds a step and reps
///   restart at the bottom.
/// - Linear: every working set at its reps adds a step; a miss repeats the target.
/// - Greyskull LP: only the last set, taken to failure, is judged. Reaching its reps adds a step
///   (two when it doubles them); missing them backs off straight away.
/// - Time: holds gain a few seconds a session.
///
/// Linear and double back off ten percent after three sessions in a row that came up short at
/// the same weight. Warm-up and drop sets aren't progressed: they're prescribed relative to the
/// working sets.
enum Progression {
    static let presets: [ClosedRange<Int>] = [3...5, 5...8, 6...10, 8...12, 10...15, 12...20]
    static let fixedReps = [3, 5, 8, 10, 12]
    static let greyskullReps = 5
    static let stallsBeforeDeload = 3
    static let deloadFactor = 0.9
    static let holdStepSeconds = 5

    enum Rule: String, CaseIterable, Identifiable {
        case double, linear, greyskull, time

        var id: String { rawValue }
    }

    struct Config: Equatable {
        var rule: Rule
        /// Double: the rep range. Linear and Greyskull: both bounds are the target reps.
        var range: ClosedRange<Int>
        var incrementKg: Double
        /// An assisted machine logs help, so harder means less of it.
        var assisted = false
    }

    enum Plan: Equatable {
        case addLoad(kg: Double)
        case addReps
        /// Came up short: same weight, same reps.
        case hold
        case deload(toKg: Double, stalls: Int)
        case addTime(seconds: Int)
    }

    static func isProgressed(_ set: SetValue) -> Bool {
        set.kind == .normal || set.kind == .failure
    }

    private static func working(_ sets: [SetValue], _ config: Config) -> [SetValue] {
        sets.filter { isProgressed($0) && (config.rule != .time || $0.durationSeconds != nil) }
    }

    /// The load a session is judged by: its heaviest working set, or the least help on an assisted machine.
    private static func load(_ sets: [SetValue], _ config: Config) -> Double {
        let weights = sets.map(\.weightKg)
        return (config.assisted ? weights.filter { $0 > 0 }.min() : weights.max()) ?? 0
    }

    private static func hit(_ sets: [SetValue], _ config: Config) -> Bool {
        let reps = config.range.upperBound
        return switch config.rule {
        case .double, .linear: sets.allSatisfy { $0.reps >= reps && $0.weightKg > 0 }
        case .greyskull: (sets.last?.reps ?? 0) >= reps
        case .time: true
        }
    }

    /// Sessions in a row, counting back from the newest, that came up short at the same weight.
    private static func stalls(_ sessions: [[SetValue]], _ config: Config) -> Int {
        func same(_ a: [SetValue], _ b: [SetValue]) -> Bool { abs(load(a, config) - load(b, config)) < 1e-6 }
        func reps(_ sets: [SetValue]) -> Int { sets.reduce(0) { $0 + $1.reps } }
        var count = 0
        for index in sessions.indices.reversed() {
            let session = sessions[index]
            if hit(session, config) { break }
            // Misses at another weight say nothing about this one.
            if index < sessions.count - 1, !same(session, sessions[index + 1]) { break }
            // Climbing a range means missing its top for weeks, so there only a session that
            // added no rep to the one before it is a stall.
            if config.rule == .double {
                guard index > 0, same(session, sessions[index - 1]), reps(session) <= reps(sessions[index - 1]) else { break }
            }
            count += 1
        }
        return count
    }

    private static func deloaded(_ weight: Double, _ config: Config) -> Double {
        let step = config.incrementKg
        // On an assisted machine easier is more help; ten percent off the help would be harder.
        if config.assisted { return weight + step }
        let snapped = (weight * deloadFactor / step).rounded() * step
        // A light load can round straight back to itself: always come down at least one step.
        return max(min(snapped, weight - step), 0)
    }

    private static func latest(_ history: [Session]) -> [SetValue] {
        PreviousPerformance.latestSets(in: history)
    }

    static func plan(history: [Session], config: Config) -> Plan? {
        let last = working(latest(history), config)
        guard !last.isEmpty else { return nil }
        if config.rule == .time { return .addTime(seconds: holdStepSeconds) }
        let weight = load(last, config)
        // Nothing on the bar to add to or take off: reps are the only lever.
        guard weight > 0 else { return .addReps }
        if hit(last, config) {
            let doubled = config.rule == .greyskull && (last.last?.reps ?? 0) >= config.range.upperBound * 2
            return .addLoad(kg: config.incrementKg * (doubled ? 2 : 1))
        }
        let sessions = history.sorted { $0.date < $1.date }.map { working($0.sets, config) }.filter { !$0.isEmpty }
        let stalled = stalls(sessions, config)
        if stalled >= (config.rule == .greyskull ? 1 : stallsBeforeDeload) {
            return .deload(toKg: deloaded(weight, config), stalls: stalled)
        }
        return config.rule == .double ? .addReps : .hold
    }

    /// Last session's sets rewritten as this session's targets; nil when there's nothing to build on.
    static func targets(history: [Session], config: Config) -> [SetValue]? {
        guard let plan = plan(history: history, config: config) else { return nil }
        let previous = latest(history)
        let weight = load(working(previous, config), config)
        return previous.map { set in
            guard isProgressed(set) else { return set }
            var next = set
            switch plan {
            case .addTime(let seconds):
                next.durationSeconds = set.durationSeconds.map { $0 + seconds }
            case .addLoad(let kg):
                next.weightKg = config.assisted ? max(0, set.weightKg - kg) : set.weightKg + kg
                next.reps = config.range.lowerBound
            case .deload(let toKg, _):
                // Shift, not overwrite, so a back-off set keeps its distance from the top set.
                next.weightKg = max(0, set.weightKg + toKg - weight)
                next.reps = config.range.lowerBound
            case .hold:
                next.reps = config.range.upperBound
            case .addReps where set.weightKg == 0:
                // Bodyweight: reps are the only lever, so the range doesn't cap them.
                next.reps += 1
            case .addReps:
                // A set already past the top keeps what it did rather than being asked for less.
                next.reps = max(set.reps, min(set.reps + 1, config.range.upperBound))
            }
            return next
        }
    }

    static func prefill(index: Int, history: [Session], currentLast: SetValue?, config: Config?) -> SetValue? {
        let base = config.flatMap { targets(history: history, config: $0) } ?? latest(history)
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
