import AppIntents
import Foundation

// LiveActivityIntents always run in the app's process, even when tapped on the Lock Screen,
// so only the app build does the work; the extension compiles them just to host the buttons.

struct CompleteSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Set"
    static var description = IntentDescription("Logs the next set of the workout in progress.")

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        LiveWorkoutActions.completeNextSet()
        #endif
        return .result()
    }
}

struct AdjustRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust Rest"

    @Parameter(title: "Seconds")
    var seconds: Int

    init() {}

    init(seconds: Int) {
        self.seconds = seconds
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        LiveWorkoutActions.adjustRest(by: seconds)
        #endif
        return .result()
    }
}

struct SkipRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip Rest"

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        LiveWorkoutActions.skipRest()
        #endif
        return .result()
    }
}
