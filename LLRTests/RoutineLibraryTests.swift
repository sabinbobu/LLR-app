import SwiftData
import XCTest
@testable import LLR

@MainActor
final class RoutineLibraryTests: XCTestCase {
    // MARK: - Display and expansion

    private func group(_ count: Int?, _ reps: Int?, _ repsMax: Int? = nil, _ kind: SetKind? = nil) -> ProgramTemplate.SetGroup {
        ProgramTemplate.SetGroup(count: count, reps: reps, repsMax: repsMax, kind: kind)
    }

    func testSetGroupText() {
        XCTAssertEqual(group(3, 5).text, "3 × 5")
        XCTAssertEqual(group(3, 8, 12).text, "3 × 8–12")
        XCTAssertEqual(group(nil, 5, nil, .failure).text, "1 × 5+")
        XCTAssertEqual(group(3, nil, nil, .failure).text, "3 × max")
        XCTAssertEqual(group(2, 5, nil, .warmup).text, "2 × 5 warm-up")
    }

    func testEntryExpandsGroupsInOrderAndCarriesRangeInNotes() {
        let entry = ProgramTemplate.Entry(
            exercise: "Bench Press (Barbell)",
            sets: [group(2, 5), group(1, 5, nil, .failure), group(2, 8, 12)],
            rest: 120,
            notes: "Pause on the chest"
        )
        XCTAssertEqual(entry.plannedSets, [
            PlannedSet(reps: 5), PlannedSet(reps: 5), PlannedSet(reps: 5, kind: .failure),
            PlannedSet(reps: 8), PlannedSet(reps: 8),
        ])
        XCTAssertEqual(entry.setsText, "2 × 5 + 1 × 5+ + 2 × 8–12")
        XCTAssertEqual(entry.routineNotes, "Aim for 8–12 reps · Pause on the chest")
    }

    // MARK: - Adopting a program

    private let json = """
    [{"id":"p","name":"Program","author":"Coach","goal":"strength","level":"beginner","equipment":"barbell",
      "daysPerWeek":3,"summary":"s","schedule":"s","progression":"p","source":"src",
      "routines":[
        {"name":"Workout A","exercises":[
          {"exercise":"Squat (Barbell)","sets":[{"count":3,"reps":5}],"rest":180},
          {"exercise":"Chin Up","sets":[{"count":2,"kind":"failure"}],"notes":"Bodyweight"}]},
        {"name":"Workout B","exercises":[{"exercise":"Squat (Barbell)","sets":[{"reps":5,"repsMax":8}]}]}]}]
    """

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        context.insert(Exercise(name: "Squat (Barbell)", muscleGroup: "Quadriceps"))
        context.insert(Exercise(name: "Chin Up", muscleGroup: "Lats"))
        return context
    }

    private func program() throws -> ProgramTemplate {
        try XCTUnwrap(RoutineLibrary.parse(Data(json.utf8)).first)
    }

    func testSaveCreatesEditableRoutinesWithPlansNotesAndRest() throws {
        let context = try makeContext()
        let program = try program()
        XCTAssertFalse(RoutineLibrary.isSaved(program, among: []))

        let saved = RoutineLibrary.save(program, into: context)

        XCTAssertEqual(saved.map(\.name), ["Program · Workout A", "Program · Workout B"])
        let dayA = try XCTUnwrap(saved.first)
        XCTAssertEqual(dayA.orderedExercises.compactMap { $0.exercise?.name }, ["Squat (Barbell)", "Chin Up"])
        let squat = try XCTUnwrap(dayA.orderedExercises.first)
        XCTAssertEqual(squat.restSeconds, 180)
        XCTAssertEqual(squat.orderedSets.map(\.reps), [5, 5, 5])
        XCTAssertEqual(squat.orderedSets.map(\.weightKg), [nil, nil, nil], "weights come from the lifter's history")
        let chins = try XCTUnwrap(dayA.orderedExercises.last)
        XCTAssertEqual(chins.orderedSets.map(\.kind), [.failure, .failure])
        XCTAssertEqual(chins.orderedSets.map(\.reps), [nil, nil])
        XCTAssertEqual(chins.notes, "Bodyweight")
        XCTAssertEqual(saved.last?.orderedExercises.first?.notes, "Aim for 5–8 reps")

        let all = try context.fetch(FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        XCTAssertEqual(all.first?.name, "Program · Workout A", "day one tops My Routines")
        XCTAssertTrue(RoutineLibrary.isSaved(program, among: all))
    }

    func testStartingADayUsesPlannedRepsAndHistoryWeights() throws {
        let context = try makeContext()
        let squat = try XCTUnwrap(RoutineLibrary.exercisesByName(in: context)["Squat (Barbell)"])
        let past = Workout(startedAt: .now.addingTimeInterval(-86_400))
        past.endedAt = past.startedAt.addingTimeInterval(3600)
        context.insert(past)
        let entry = WorkoutExercise(order: 0)
        context.insert(entry)
        entry.exercise = squat
        past.exercises.append(entry)
        for index in 0..<3 {
            let set = SetEntry(order: index, weightKg: 100, reps: 3)
            set.completedAt = past.startedAt
            context.insert(set)
            entry.sets.append(set)
        }

        let program = try program()
        let day = try XCTUnwrap(program.routines.first)
        let workout = WorkoutFactory.start(RoutineLibrary.plan(for: day, in: context), named: RoutineLibrary.routineName(program, day), in: context)

        XCTAssertEqual(workout.title, "Program · Workout A")
        XCTAssertNil(workout.endedAt)
        let sets = try XCTUnwrap(workout.orderedExercises.first?.orderedSets)
        XCTAssertEqual(sets.map(\.reps), [5, 5, 5], "the program's reps")
        XCTAssertEqual(sets.map(\.weightKg), [100, 100, 100], "the lifter's own weights")
        XCTAssertEqual(squat.restSeconds, 180)
    }

    func testSingleDayProgramKeepsItsOwnName() throws {
        let single = try XCTUnwrap(RoutineLibrary.parse(Data("""
        [{"id":"g","name":"Golden","author":"A","goal":"muscle","level":"beginner","equipment":"barbell","daysPerWeek":3,
          "summary":"s","schedule":"s","progression":"p","source":"s",
          "routines":[{"name":"Full Body","exercises":[{"exercise":"Chin Up","sets":[{"count":3}]}]}]}]
        """.utf8)).first)
        XCTAssertEqual(RoutineLibrary.routineName(single, single.routines[0]), "Golden")
    }

    // MARK: - The bundled library itself

    func testBundledLibraryIsValidAgainstTheExerciseLibrary() throws {
        let bundle = Bundle(for: Exercise.self)
        let library = try RoutineLibrary.parse(Data(contentsOf: XCTUnwrap(bundle.url(forResource: "routine_library", withExtension: "json"))))
        let exercises = try ExerciseLibrary.parseSeeds(Data(contentsOf: XCTUnwrap(bundle.url(forResource: "exercises", withExtension: "json"))))
        let names = Set(exercises.map(\.name))

        XCTAssertFalse(library.isEmpty)
        XCTAssertEqual(Set(library.map(\.id)).count, library.count, "ids must be unique")
        for program in library {
            XCTAssertFalse(program.routines.isEmpty, program.id)
            XCTAssertTrue((1...7).contains(program.daysPerWeek), program.id)
            XCTAssertEqual(Set(program.routines.map(\.name)).count, program.routines.count, "\(program.id): day names must be unique")
            for day in program.routines {
                XCTAssertFalse(day.exercises.isEmpty, "\(program.id) · \(day.name)")
                for entry in day.exercises {
                    let label = "\(program.id) · \(day.name) · \(entry.exercise)"
                    XCTAssertTrue(names.contains(entry.exercise), "not in the exercise library: \(label)")
                    XCTAssertFalse(entry.sets.isEmpty, label)
                    if let rest = entry.rest {
                        XCTAssertTrue(RestDuration.choices.contains(rest), "rest \(rest)s isn't a choice: \(label)")
                    }
                    for set in entry.sets {
                        XCTAssertGreaterThanOrEqual(set.count ?? 1, 1, label)
                        if let reps = set.reps { XCTAssertGreaterThanOrEqual(reps, 1, label) }
                        if let top = set.repsMax {
                            XCTAssertGreaterThan(top, try XCTUnwrap(set.reps, "a range needs a bottom: \(label)"), label)
                        }
                    }
                }
            }
        }
    }
}
