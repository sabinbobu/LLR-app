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

    func testImportNeverAttachesGymHistoryToAKinetoExerciseOfTheSameName() throws {
        let context = try makeContext()
        // A user-made Kineto exercise; built-ins like Plank share one gym row and can't collide.
        let kineto = Exercise(name: "Clamshell", muscleGroup: "Glutes", isCustom: true)
        kineto.sectionRaw = "kineto"
        context.insert(kineto)
        let csv = """
        Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE
        2021-01-02 09:00:00,"Hips",20m,"Clamshell",1,0,15,0,0,,,
        """

        let summary = WorkoutImporter.apply(try WorkoutCSV.parse(csv, strongUnit: .kg), into: context)

        let entry = try XCTUnwrap(context.fetch(FetchDescriptor<Workout>()).first?.orderedExercises.first)
        XCTAssertEqual(entry.exercise?.sectionRaw, "gym", "Kineto exercises are hidden from gym history and the picker")
        XCTAssertNotEqual(entry.exercise?.id, kineto.id)
        XCTAssertEqual(summary.newExercises, ["Clamshell"])
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

    func testReimportingOwnExportSkipsWorkoutsLoggedHere() throws {
        let context = try makeContext()
        let bench = Exercise(name: "Bench Press", muscleGroup: "Chest")
        context.insert(bench)
        // Logged live: Date.now carries sub-second precision the export's whole seconds can't keep.
        let workout = Workout(startedAt: Date(timeIntervalSince1970: 1_700_000_000.734))
        workout.endedAt = workout.startedAt.addingTimeInterval(3600)
        context.insert(workout)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = bench
        workout.exercises.append(entry)
        let set = SetEntry(order: 0, weightKg: 80, reps: 5)
        set.completedAt = workout.startedAt
        context.insert(set)
        entry.sets.append(set)

        let csv = WorkoutExport.strongCSV([workout], unit: .kg)
        let summary = WorkoutImporter.apply(try WorkoutCSV.parse(csv, strongUnit: .kg), into: context)

        XCTAssertEqual(summary.duplicates, 1)
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

    func testEffortSurvivesImportAndExportAsRPE() throws {
        let context = try makeContext()
        let text = """
        Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE
        2021-01-02 09:00:00,"Push",45m,"Bench Press (Barbell)",1,80.0,8,0,0,,,8.5
        2021-01-02 09:00:00,"Push",45m,"Bench Press (Barbell)",2,80.0,7,0,0,,,10
        2021-01-02 09:00:00,"Push",45m,"Bench Press (Barbell)",3,80.0,6,0,0,,,
        """
        _ = WorkoutImporter.apply(try WorkoutCSV.parse(text, strongUnit: .kg), into: context)
        let workout = try XCTUnwrap(context.fetch(FetchDescriptor<Workout>()).first)
        XCTAssertEqual(workout.orderedExercises.first?.orderedSets.map(\.rir), [1.5, 0, nil])

        let csv = WorkoutExport.strongCSV([workout], unit: .kg)
        let rpeColumn = CSV.parse(csv, delimiter: ",").dropFirst().map { $0.last ?? "" }
        XCTAssertEqual(Array(rpeColumn), ["8.5", "10", ""])
        XCTAssertEqual(try WorkoutCSV.parse(csv, strongUnit: .kg).workouts, try WorkoutCSV.parse(text, strongUnit: .kg).workouts)
    }

    func testExportRoundTripsDurationSets() throws {
        let context = try makeContext()
        let text = """
        Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE
        2021-01-02 09:00:00,"Back Care",20m,"Bird Dog",1,0,5,0,15,,,
        2021-01-02 09:00:00,"Back Care",20m,"Bird Dog",2,0,5,0,15,,,
        """
        _ = WorkoutImporter.apply(try WorkoutCSV.parse(text, strongUnit: .kg), into: context)

        let csv = WorkoutExport.strongCSV(try context.fetch(FetchDescriptor<Workout>()), unit: .kg)
        let reparsed = try WorkoutCSV.parse(csv, strongUnit: .kg)
        XCTAssertEqual(reparsed.workouts.first?.exercises.first?.sets, [
            ImportedSet(weightKg: 0, reps: 5, kind: .normal, durationSeconds: 15),
            ImportedSet(weightKg: 0, reps: 5, kind: .normal, durationSeconds: 15),
        ])
    }

    func testKinetoCSVKeepsAPainOnlySessionAsOneRow() throws {
        let context = try makeContext()
        let workout = Workout(startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        workout.endedAt = workout.startedAt.addingTimeInterval(120)
        workout.section = .kineto
        workout.name = "Morning"
        workout.backPainBefore = 6
        workout.legPainBefore = 2
        context.insert(workout)
        try context.save()

        let rows = WorkoutExport.kinetoCSV([workout]).split(separator: "\n")
        XCTAssertEqual(rows.count, 2, "header + exactly one row, even though nothing was ticked")
        XCTAssertTrue(rows[1].hasSuffix("6,2,,,,"), "back/leg pain-before must survive with the after/spread fields left blank")
    }

    func testKinetoCSVWritesOneRowPerCompletedSet() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Bird Dog", muscleGroup: "Lower Back")
        context.insert(exercise)
        let workout = Workout(startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        workout.endedAt = workout.startedAt.addingTimeInterval(600)
        workout.section = .kineto
        context.insert(workout)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = exercise
        workout.exercises.append(entry)
        for index in 0..<2 {
            let set = SetEntry(order: index, weightKg: 0, reps: 1)
            set.durationSeconds = 15
            set.completedAt = workout.startedAt
            context.insert(set)
            entry.sets.append(set)
        }
        try context.save()

        let rows = WorkoutExport.kinetoCSV([workout]).split(separator: "\n")
        XCTAssertEqual(rows.count, 3, "header + one row per completed set")
        XCTAssertTrue(rows[1].contains("Bird Dog,1,1,15"))
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
