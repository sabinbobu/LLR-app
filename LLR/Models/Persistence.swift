import SwiftData

/// One container per process: the UI and Lock Screen intents (which can run with no window open)
/// must write to the same store and see each other's changes.
@MainActor
enum Persistence {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
                Routine.self, RoutineExercise.self, RoutineSetPlan.self
            )
        } catch {
            // Without the store there is nothing to show; failing loudly beats silently losing history.
            fatalError("SwiftData store failed to open: \(error)")
        }
    }()
}
