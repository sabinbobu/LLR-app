import Foundation

/// What the Workout tab shows, decided in one place so it can be tested without a view.
enum WorkoutTabModel {
    static let quickStartLimit = 5
    static let repeatLimit = 3

    /// Gym routines only (Kineto routines live in their own hub), newest first.
    static func recentRoutines(_ routines: [Routine], limit: Int = quickStartLimit) -> [Routine] {
        let gym = routines.filter { $0.section == .gym }
        return Array(gym.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    /// Finished gym workouts with something to copy. Compared on the raw value because a run's "run"
    /// falls back to `.gym` in `Workout.section`.
    static func repeatCandidates(_ workouts: [Workout], limit: Int = repeatLimit) -> [Workout] {
        let finished = workouts.filter { $0.endedAt != nil && $0.sectionRaw == "gym" && !$0.exercises.isEmpty }
        return Array(finished.sorted { $0.startedAt > $1.startedAt }.prefix(limit))
    }

    /// The onboarding row is for people who have never finished a gym workout.
    static func showsGettingStarted(finishedGymWorkouts: Int) -> Bool {
        finishedGymWorkouts == 0
    }
}
