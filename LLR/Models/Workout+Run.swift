import Foundation

extension Workout {
    var isRun: Bool { sectionRaw == RunStats.sectionRaw }

    /// Load of a finished run in MET-hours; nil for lifts and for runs logged before distance existed.
    var runMetHours: Double? {
        guard isRun, endedAt != nil, let km = distanceKm else { return nil }
        return RunLoad.metHours(km: km, seconds: duration)
    }

    /// Per-muscle fatigue from a run, in the same currency as working sets. Kept out of
    /// `recoveryEntries` on purpose: a run is not a hard set, so Weekly Volume and effort stats never see it.
    var runRecoveryEntries: [MuscleRecovery.Entry] {
        guard let hours = runMetHours, let finished = endedAt, let km = distanceKm else { return [] }
        let name = "Run \(km.formatted(.number.precision(.fractionLength(0...1)))) km"
        return RunLoad.muscleLoads(metHours: hours).map { load in
            MuscleRecovery.Entry(exerciseName: name, muscle: load.muscle.rawValue, secondaryMuscles: [],
                                 completedAt: finished, load: load.points)
        }
    }

    /// Everything that tires a muscle: lifting sets and runs.
    var exhaustionEntries: [MuscleRecovery.Entry] { recoveryEntries + runRecoveryEntries }

    /// Whole-body exhaustion (0–100) this run left at its end, before it fades.
    var runExhaustionPercent: Double? { runMetHours.map(RunLoad.overallExhaustionPercent(metHours:)) }
}
