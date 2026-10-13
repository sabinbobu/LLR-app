import Foundation

/// Cardio and mobility entries are logged by time, not weight × reps. When one opens a workout it
/// is a warm-up: tagged `.warmup` so volume, PRs and Weekly Volume skip it, and it rests for nothing.
enum TimedWarmup {
    static let defaultSeconds = 300
    private static let timedNames: Set<String> = ["Stretching", "Dynamic Mobility Warm-up"]

    static func isTimedByDefault(muscleGroup: String, name: String) -> Bool {
        muscleGroup == MuscleGroup.cardio.rawValue || timedNames.contains(name)
    }

    /// nil = log it the ordinary way. Past weight/reps history wins so nobody's old Cycling log flips format.
    static func prefill(muscleGroup: String, name: String, history: [Session], isFirstInWorkout: Bool) -> SetValue? {
        guard isTimedByDefault(muscleGroup: muscleGroup, name: name) else { return nil }
        let past = PreviousPerformance.latestSets(in: history)
        if !past.isEmpty && !past.allSatisfy({ $0.durationSeconds != nil }) { return nil }
        let seconds = past.last?.durationSeconds ?? defaultSeconds
        return SetValue(weightKg: 0, reps: 1, kind: isFirstInWorkout ? .warmup : .normal, durationSeconds: seconds)
    }

    static func isTimedWarmup(kind: SetKind, durationSeconds: Int?) -> Bool {
        kind == .warmup && durationSeconds != nil
    }
}
