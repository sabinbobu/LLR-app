import SwiftData
import XCTest
@testable import LLR

@MainActor
final class KinetoCatalogTests: XCTestCase {
    /// Spine-loading studies name these as the highest-compression exercises for their category
    /// (Axler & McGill 1997 for abdominals, Callaghan 1998 for extension) — the catalog must
    /// never recommend them, no matter what future edits add.
    private let excludedHighLoadNames: Set<String> = [
        "Sit Up", "Lying Leg Raise", "Hanging Leg Raise", "Superman", "Back Extension (Hyperextension)",
    ]

    func testBundledCatalogIsValid() throws {
        let bundle = Bundle(for: Exercise.self)
        let data = try Data(contentsOf: XCTUnwrap(bundle.url(forResource: "kineto_exercises", withExtension: "json")))
        let (exercises, libraryEntries) = try KinetoCatalog.parse(data)

        XCTAssertFalse(exercises.isEmpty)
        XCTAssertEqual(Set(exercises.map(\.name)).count, exercises.count, "names must be unique")
        XCTAssertTrue(excludedHighLoadNames.isDisjoint(with: Set(exercises.map(\.name))))

        for exercise in exercises {
            XCTAssertFalse(exercise.sources.isEmpty, "\(exercise.name) has no source")
            for source in exercise.sources {
                XCTAssertTrue(source.url.hasPrefix("https://"), "\(exercise.name): \(source.url)")
            }
            XCTAssertFalse(exercise.levels.isEmpty, "\(exercise.name) has no dosing levels")
        }

        // Every new (non-★) exercise must carry real library fields so it can seed an Exercise row.
        for entry in libraryEntries {
            XCTAssertFalse(entry.muscle.isEmpty, entry.name)
        }
    }

    func testBundledLibraryHasNoHighLoadExercises() throws {
        // Belt and braces: even the main exercises.json library existing separately doesn't mean
        // the *Kineto catalog* ever points at one of these names.
        let bundle = Bundle(for: Exercise.self)
        let data = try Data(contentsOf: XCTUnwrap(bundle.url(forResource: "kineto_exercises", withExtension: "json")))
        let (exercises, _) = try KinetoCatalog.parse(data)
        XCTAssertTrue(excludedHighLoadNames.isDisjoint(with: Set(exercises.map(\.name))))
    }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func testSeedingResolvesEveryCatalogNameAndNeverDuplicatesOrOverridesSharedRows() throws {
        let context = try makeContext()
        ExerciseLibrary.seedIfNeeded(context)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        let byName = Dictionary(uniqueKeysWithValues: all.map { ($0.name, $0) })
        for exercise in KinetoCatalog.exercises {
            XCTAssertNotNil(byName[exercise.name], "\(exercise.name) never got seeded")
        }

        let birdDog = try XCTUnwrap(byName["Bird Dog"])
        let birdDogFieldsBefore = (birdDog.muscleGroup, birdDog.equipment, birdDog.instructions)

        ExerciseLibrary.seedIfNeeded(context)

        let afterSecondPass = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(afterSecondPass.count, all.count, "a second sync must not insert duplicates")
        XCTAssertEqual(birdDog.muscleGroup, birdDogFieldsBefore.0, "a Kineto-only entry must never overwrite the gym library's fields")
        XCTAssertEqual(birdDog.equipment, birdDogFieldsBefore.1)
        XCTAssertEqual(birdDog.instructions, birdDogFieldsBefore.2)
    }
}
