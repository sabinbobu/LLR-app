import SwiftData
import SwiftUI

@main
struct LLRApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self)
        } catch {
            // Without the store there is nothing to show; failing loudly beats silently losing history.
            fatalError("SwiftData store failed to open: \(error)")
        }
        ExerciseLibrary.seedIfNeeded(container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
