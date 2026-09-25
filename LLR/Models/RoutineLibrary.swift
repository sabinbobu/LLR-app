import Foundation
import SwiftData

/// The bundled programs from well-known coaches. Adopting one copies it into ordinary routines,
/// so the user can edit it freely; the library itself never changes.
enum RoutineLibrary {
    static func parse(_ data: Data) throws -> [ProgramTemplate] {
        try JSONDecoder().decode([ProgramTemplate].self, from: data)
    }

    static let programs: [ProgramTemplate] = {
        guard let url = Bundle.main.url(forResource: "routine_library", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let programs = try? parse(data)
        else { return [] }
        return programs
    }()

    static func routineName(_ program: ProgramTemplate, _ day: ProgramTemplate.Day) -> String {
        program.routines.count == 1 ? program.name : "\(program.name) · \(day.name)"
    }

    static func isSaved(_ program: ProgramTemplate, among routines: [Routine]) -> Bool {
        let names = Set(routines.map(\.name))
        return program.routines.allSatisfy { names.contains(routineName(program, $0)) }
    }

    /// Library entries win over a custom exercise that happens to share the name.
    static func exercisesByName(in context: ModelContext) -> [String: Exercise] {
        let all = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var byName: [String: Exercise] = [:]
        for exercise in all.sorted(by: { !$0.isCustom && $1.isCustom }) where byName[exercise.name] == nil {
            byName[exercise.name] = exercise
        }
        return byName
    }

    @discardableResult
    static func save(_ program: ProgramTemplate, into context: ModelContext) -> [Routine] {
        let byName = exercisesByName(in: context)
        var created: [Routine] = []
        // Created last-to-first: My Routines lists newest first, so day one ends up on top.
        for day in program.routines.reversed() {
            let routine = Routine(name: routineName(program, day))
            context.insert(routine)
            for (order, entry) in day.exercises.enumerated() {
                guard let exercise = byName[entry.exercise] else { continue }
                let item = RoutineExercise(order: order)
                context.insert(item)
                item.exercise = exercise
                item.notes = entry.routineNotes
                item.restSeconds = entry.rest
                routine.exercises.append(item)
                for (index, planned) in entry.plannedSets.enumerated() {
                    let plan = RoutineSetPlan(order: index, weightKg: planned.weightKg, reps: planned.reps)
                    plan.kind = planned.kind
                    plan.durationSeconds = planned.durationSeconds
                    context.insert(plan)
                    item.sets.append(plan)
                }
            }
            created.insert(routine, at: 0)
        }
        try? context.save()
        return created
    }

    static func plan(for day: ProgramTemplate.Day, in context: ModelContext) -> [WorkoutFactory.PlannedExercise] {
        let byName = exercisesByName(in: context)
        return day.exercises.compactMap { entry in
            byName[entry.exercise].map {
                WorkoutFactory.PlannedExercise(exercise: $0, restSeconds: entry.rest, sets: entry.plannedSets)
            }
        }
    }
}
