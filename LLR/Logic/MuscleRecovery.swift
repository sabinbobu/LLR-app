import Foundation

/// A heuristic, not physiology: recent working-set load per muscle, decayed linearly to zero over a
/// recovery window. It surfaces what's been hit hard lately, not a clinical readiness measurement.
enum MuscleRecovery {
    struct Entry {
        let exerciseName: String
        let muscle: String
        let secondaryMuscles: [String]
        let completedAt: Date
        /// Reps in reserve, nil when the set was never rated; recovery ignores it, Weekly Volume filters on it.
        var rir: Double? = nil
        /// Fatigue points this entry is worth on its primary muscle: 1 for a working set, more for a run.
        var load: Double = 1.0
    }

    struct Status {
        let muscle: MuscleGroup
        let percent: Double
        let lastTrained: Date?
        let lastExerciseName: String?
    }

    /// Bigger, slower-clearing muscle groups get the longer window; everything else clears in two days.
    private static let longWindowMuscles: Set<MuscleGroup> = [
        .chest, .lats, .upperBack, .lowerBack, .quadriceps, .hamstrings, .glutes,
    ]

    static func windowHours(for muscle: MuscleGroup) -> Double { longWindowMuscles.contains(muscle) ? 72 : 48 }

    /// 100% with no history. A primary working set is worth 1.0 fatigue point, a secondary 0.5; about
    /// 10 points (roughly a hard session) reads 0%, clearing back to 100% once every set that fed it
    /// has aged past its own window.
    static func statuses(for entries: [Entry], now: Date = .now) -> [MuscleGroup: Status] {
        var fatigue: [MuscleGroup: Double] = [:]
        var lastTrained: [MuscleGroup: Date] = [:]

        var lastExercise: [MuscleGroup: String] = [:]
        func apply(_ rawMuscle: String, load: Double, entry: Entry) {
            guard let group = MuscleGroup(rawValue: rawMuscle), group.isTrainable else { return }
            let hoursAgo = now.timeIntervalSince(entry.completedAt) / 3600
            guard hoursAgo >= 0 else { return }
            let remaining = max(0, 1 - hoursAgo / windowHours(for: group))
            guard remaining > 0 else { return }
            fatigue[group, default: 0] += load * remaining
            if entry.completedAt > (lastTrained[group] ?? .distantPast) {
                lastTrained[group] = entry.completedAt
                lastExercise[group] = entry.exerciseName
            }
        }

        for entry in entries {
            apply(entry.muscle, load: entry.load, entry: entry)
            for secondary in entry.secondaryMuscles { apply(secondary, load: 0.5 * entry.load, entry: entry) }
        }

        return Dictionary(uniqueKeysWithValues: MuscleGroup.allCases.filter(\.isTrainable).map { group in
            let percent = max(0, 100 * (1 - (fatigue[group] ?? 0) / 10))
            return (group, Status(muscle: group, percent: percent, lastTrained: lastTrained[group], lastExerciseName: lastExercise[group]))
        })
    }

    /// `systemicExhaustion` (0–100, from recent runs) scales the muscle average down: a hard run
    /// tires the whole body, not just the legs the muscle rows show.
    static func overallPercent(_ statuses: [MuscleGroup: Status], systemicExhaustion: Double = 0) -> Double {
        guard !statuses.isEmpty else { return 100 }
        let average = statuses.values.reduce(0) { $0 + $1.percent } / Double(statuses.count)
        return average * (1 - min(max(systemicExhaustion, 0), 100) / 100)
    }
}
