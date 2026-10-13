import Observation

/// Owned by MainTabView so any tab can open or resume the in-progress workout.
@MainActor
@Observable
final class ActiveWorkoutPresenter {
    var presented: Workout?
    var summary: Workout?
    /// Held until the cover has dismissed; presenting a sheet during the dismissal drops it.
    var pendingSummary: Workout?

    func present(_ workout: Workout) { presented = workout }

    func coverDismissed() {
        summary = pendingSummary
        pendingSummary = nil
    }
}
