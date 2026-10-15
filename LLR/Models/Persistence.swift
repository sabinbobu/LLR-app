import Foundation
import SwiftData

/// One container per process: the UI and Lock Screen intents (which can run with no window open)
/// must write to the same store and see each other's changes.
@MainActor
enum Persistence {
    static let container: ModelContainer = open(ModelConfiguration())

    private static func make(_ configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            BodyMeasurement.self, ProgressPhoto.self, FoodEntry.self, ExerciseMedia.self,
            configurations: configuration
        )
    }

    /// A store that won't open must not brick the app on every launch. The unreadable files are set
    /// aside (not deleted) so history can still be recovered by hand, and the app starts empty.
    static func open(_ configuration: ModelConfiguration) -> ModelContainer {
        do {
            return try make(configuration)
        } catch {
            print("SwiftData store failed to open, setting it aside: \(error)")
            quarantine(configuration.url)
        }
        do {
            return try make(configuration)
        } catch {
            // Last resort so the app still launches; nothing written this run will persist.
            do {
                return try make(ModelConfiguration(isStoredInMemoryOnly: true))
            } catch {
                fatalError("SwiftData could not create even an in-memory store: \(error)")
            }
        }
    }

    static func quarantine(_ storeURL: URL) {
        let stamp = Int(Date.now.timeIntervalSince1970)
        // Unencoded: the real store sits under "Application Support", and path() would turn the space
        // into %20, naming a file that doesn't exist so nothing ever got set aside.
        let path = storeURL.path(percentEncoded: false)
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: path + suffix)
            let target = URL(fileURLWithPath: path + suffix + ".corrupt-\(stamp)")
            try? FileManager.default.moveItem(at: source, to: target)
        }
    }
}
