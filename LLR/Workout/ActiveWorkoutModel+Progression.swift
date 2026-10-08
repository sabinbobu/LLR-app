import Foundation

extension ActiveWorkoutModel {
    func setProgression(_ rule: Progression.Rule?, range: ClosedRange<Int>?, for entry: WorkoutExercise) {
        entry.exercise?.setProgression(rule, range: range)
        retarget(entry)
    }

    func setProgressionStep(_ kg: Double?, for entry: WorkoutExercise) {
        entry.exercise?.progressionStepKg = kg
        retarget(entry)
    }

    /// Re-targets only unticked sets: logged sets are history, whatever the rule says now.
    private func retarget(_ entry: WorkoutExercise) {
        guard let exercise = entry.exercise else { return }
        let history = history(for: exercise)
        for (index, set) in entry.orderedSets.enumerated() where set.completedAt == nil {
            guard let target = exercise.progressionPrefill(index: index, history: history, currentLast: nil) else { continue }
            set.weightKg = target.weightKg
            set.reps = target.reps
            if let seconds = target.durationSeconds { set.durationSeconds = seconds }
        }
        syncLockScreen()
    }
}
