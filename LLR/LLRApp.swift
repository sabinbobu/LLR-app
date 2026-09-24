import SwiftData
import SwiftUI

@main
struct LLRApp: App {
    private let container = Persistence.container

    init() {
        ExerciseLibrary.seedIfNeeded(container.mainContext)
        // A relaunch empties the in-memory rest timer; the Lock Screen still shows the rest in progress.
        LiveWorkoutActivity.restoreRest()
        LiveWorkoutActivity.sync()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
