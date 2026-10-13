import Observation

/// Owned by MainTabView so any tab can open or resume the in-progress workout.
@MainActor
@Observable
final class ActiveWorkoutPresenter {
    var presented: Workout?
    var summary: Workout?
    /// Held until the cover has dismissed; presenting a sheet during the dismissal drops it.
    var pendingSummary: Workout?

    /// A cool-down chosen on the summary sheet, started once that sheet is gone.
    var cooldown: Workout?

    func present(_ workout: Workout) { presented = workout }

    func coverDismissed() {
        summary = pendingSummary
        pendingSummary = nil
    }

    func summaryDismissed() {
        guard let next = cooldown else { return }
        cooldown = nil
        present(next)
    }
}
