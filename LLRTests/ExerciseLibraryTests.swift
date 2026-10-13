import SwiftData
import XCTest
@testable import LLR

final class ExerciseLibraryTests: XCTestCase {
    func testParsesEveryField() throws {
        let json = """
        [{"Name": "Bench Press (Barbell)", "Muscle": "Chest", "Equipment": ["Barbell"], "Primary": "Chest",
          "Secondary": ["Triceps", "Shoulders"], "Howto": ["Lie on the bench.", "Press."]}]
        """.data(using: .utf8)!
        let seeds = try ExerciseLibrary.parseSeeds(json)
        XCTAssertEqual(seeds, [LibraryExercise(
            name: "Bench Press (Barbell)",
            muscle: "Chest",
            equipment: ["Barbell"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            instructions: ["Lie on the bench.", "Press."]
        )])
    }

    func testLegacyNameAndMuscleOnlyShapeStillParses() throws {
        let json = #"[{"Name": "Squat (Barbell)", "Muscle": "Quadriceps"}]"#.data(using: .utf8)!
        let seed = try XCTUnwrap(ExerciseLibrary.parseSeeds(json).first)
        XCTAssertEqual(seed.muscle, "Quadriceps")
        XCTAssertEqual(seed.equipment, [])
        XCTAssertEqual(seed.secondaryMuscles, [])
        XCTAssertEqual(seed.instructions, [])
    }

    func testPrimaryWinsOverMuscle() throws {
        let json = #"[{"Name": "X", "Muscle": "Chest", "Primary": "Triceps"}]"#.data(using: .utf8)!
        XCTAssertEqual(try ExerciseLibrary.parseSeeds(json).first?.muscle, "Triceps")
    }

    func testEmptyArrayParsesToEmpty() throws {
        XCTAssertTrue(try ExerciseLibrary.parseSeeds("[]".data(using: .utf8)!).isEmpty)
    }

    func testMalformedJSONThrows() {
        XCTAssertThrowsError(try ExerciseLibrary.parseSeeds("not json".data(using: .utf8)!))
    }

    func testBundledLibraryHasAllFieldsForEveryExercise() throws {
        let url = try XCTUnwrap(Bundle(for: Exercise.self).url(forResource: "exercises", withExtension: "json"))
        let seeds = try ExerciseLibrary.parseSeeds(Data(contentsOf: url))
        XCTAssertEqual(seeds.count, 453)
        XCTAssertEqual(Set(seeds.map(\.name)).count, seeds.count, "names are the sync key, so they must be unique")
        let bench = try XCTUnwrap(seeds.first { $0.name == "Bench Press (Barbell)" })
        XCTAssertEqual(bench.equipment, ["Barbell"])
        XCTAssertEqual(bench.secondaryMuscles, ["Triceps", "Shoulders"])
        XCTAssertEqual(bench.instructions.count, 7)
    }

    func testPopularIsTheLeadingBlockBeforeAToZRestarts() {
        let names = ["Bench Press", "Squat", "21s Curl", "Ab Wheel", "Bench Press 2"]
        XCTAssertEqual(ExerciseLibrary.popularNames(in: names), ["Bench Press", "Squat"])
    }

    func testPlainAToZFileHasNoPopularBlock() {
        XCTAssertEqual(ExerciseLibrary.popularNames(in: ["Ab Wheel", "Bench Press", "Squat"]), [])
        XCTAssertEqual(ExerciseLibrary.popularNames(in: []), [])
    }

    func testBundledPopularSetMatchesTheCuratedBlock() {
        let popular = ExerciseLibrary.popular
        XCTAssertEqual(popular.count, 20)
        XCTAssertEqual(popular.first, "Bench Press (Barbell)")
        XCTAssertEqual(popular.last, "Triceps Rope Pushdown")
    }

    // MARK: - Sync against a store

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private let bench = LibraryExercise(
        name: "Bench Press (Barbell)", muscle: "Chest", equipment: ["Barbell"],
        secondaryMuscles: ["Triceps"], instructions: ["Lie on the bench."]
    )

    func testSyncInsertsNewExercisesWithAllFields() throws {
        let context = try makeContext()
        ExerciseLibrary.sync([bench], into: context)
        let stored = try XCTUnwrap(context.fetch(FetchDescriptor<Exercise>()).first)
        XCTAssertEqual(stored.name, "Bench Press (Barbell)")
        XCTAssertEqual(stored.equipment, ["Barbell"])
        XCTAssertEqual(stored.secondaryMuscles, ["Triceps"])
        XCTAssertEqual(stored.instructions, ["Lie on the bench."])
        XCTAssertFalse(stored.isCustom)
    }

    /// The upgrade path: a store seeded by the old name+muscle library gets the new fields in place,
    /// keeping the same row so logged sets stay attached to it.
    func testSyncBackfillsExistingBuiltInRow() throws {
        let context = try makeContext()
        let old = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Chest")
        context.insert(old)
        try context.save()

        ExerciseLibrary.sync([bench], into: context)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, old.id)
        XCTAssertEqual(all.first?.instructions, ["Lie on the bench."])
    }

    func testSyncNeverTouchesOrDuplicatesCustomExercise() throws {
        let context = try makeContext()
        let custom = Exercise(name: "Bench Press (Barbell)", muscleGroup: "Shoulders", isCustom: true)
        context.insert(custom)
        try context.save()

        ExerciseLibrary.sync([bench], into: context)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.muscleGroup, "Shoulders")
        XCTAssertEqual(all.first?.instructions, [])
    }

    func testSyncIsIdempotent() throws {
        let context = try makeContext()
        ExerciseLibrary.sync([bench], into: context)
        ExerciseLibrary.sync([bench], into: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 1)
    }
}
