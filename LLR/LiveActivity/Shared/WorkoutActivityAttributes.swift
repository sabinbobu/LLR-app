import ActivityKit
import Foundation

/// Compiled into both the app and the widget extension: the extension only renders this,
/// the app is the only side that ever builds or changes it.
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// nil once every set is ticked: the activity then just points back to Finish.
        var exerciseName: String?
        var setLabel: String
        var target: String
        /// A set with no reps can't be logged blind; it needs the app to fill it in first.
        var canComplete: Bool
        var completedSets: Int
        var totalSets: Int
        var restStartedAt: Date?
        var restEndsAt: Date?

        var isResting: Bool {
            guard let restEndsAt else { return false }
            return restEndsAt > .now
        }
    }

    var workoutName: String
    var startedAt: Date
}
