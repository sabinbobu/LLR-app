import SwiftData
import XCTest
@testable import LLR

final class WorkoutImporterTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private let strong = """
    Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE
    2021-01-02 09:00:00,"Olympic",45m,"Clean (Barbell)",W,40.0,3,0,0,,"Snappy",
    2021-01-02 09:00:00,"Olympic",45m,"Clean (Barbell)",1,70.0,2,0,0,,,
    2021-01-02 09:00:00,"Olympic",45m,"Snatch Ballance",1,50.0,3,0,0,,,
    """

    func testImportReusesLibraryExercisesAndCreatesCustomOnes() throws {
        let context = try makeContext()
        let clean = Exercise(name: "Clean", muscleGroup: "Full Body")
        clean.equipment = ["Barbell"]
        context.insert(clean)

        let summary = WorkoutImporter.apply(try WorkoutCSV.parse(strong, strongUnit: .kg), into: context)

        XCTAssertEqual(summary, ImportSummary(workouts: 1, sets: 3, newExercises: ["Snatch Ballance"]))
        let workout = try XCTUnwrap(context.fetch(FetchDescriptor<Workout>()).first)
        XCTAssertEqual(workout.title, "Olympic")
        XCTAssertEqual(workout.notes, "Snappy")
        XCTAssertNotNil(workout.endedAt, "imports are finished history, never a workout to resume")
        let entries = workout.orderedExercises
        XCTAssertEqual(entries.first?.exercise?.id, clean.id)
        XCTAssertEqual(entries.first?.completedSets.map(\.kind), [.warmup, .normal])
        let custom = try XCTUnwrap(entries.last?.exercise)
        XCTAssertTrue(custom.isCustom)
        XCTAssertEqual(custom.muscleGroup, "Other")
    }

    func testImportedHistoryFeedsPreviousPerformance() throws {
        let context = try makeContext()
        _ = WorkoutImporter.apply(try WorkoutCSV.parse(strong, strongUnit: .kg), into: context)
        let clean = try XCTUnwrap(context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "Clean (Barbell)" })
        XCTAssertEqual(PreviousPerformance.latestSets(in: clean.sessions()).map(\.weightKg), [40, 70])
    }

    func testReimportSkipsWorkoutsAlreadyHere() throws {
        let context = try makeContext()
        let parsed = try WorkoutCSV.parse(strong, strongUnit: .kg)
        _ = WorkoutImporter.apply(parsed, into: context)
        let again = WorkoutImporter.apply(parsed, into: context)
        XCTAssertEqual(again.workouts, 0)
        XCTAssertEqual(again.duplicates, 1)
        XCTAssertEqual(again.newExercises, [])
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Workout>()), 1)
    }

    func testExportRoundTripsThroughImport() throws {
        let source = try makeContext()
        _ = WorkoutImporter.apply(try WorkoutCSV.parse(strong, strongUnit: .kg), into: source)
        let csv = WorkoutExport.strongCSV(try source.fetch(FetchDescriptor<Workout>()), unit: .kg)

        let reparsed = try WorkoutCSV.parse(csv, strongUnit: .kg)
        let original = try WorkoutCSV.parse(strong, strongUnit: .kg)
        XCTAssertEqual(reparsed.workouts, original.workouts)
    }

    func testExportLeavesOutUnfinishedWorkoutsAndUnticked() throws {
        let context = try makeContext()
        let open = Workout()
        context.insert(open)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = Exercise(name: "Squat (Barbell)", muscleGroup: "Quadriceps")
        open.exercises.append(entry)
        XCTAssertEqual(WorkoutExport.strongCSV([open], unit: .kg), CSV.line(WorkoutExport.header) + "\n")
    }
}
