import Foundation
import SwiftData

/// A value copy of one routine, so a swipe-delete can be undone exactly. The id and creation date
/// are kept because the routine lists sort by creation date: a restored routine must come back in
/// the same slot, not at the top.
struct RoutineSnapshot: Equatable {
    struct PlanCopy: Equatable {
        let order: Int
        let weightKg: Double?
        let reps: Int?
        let kindRaw: String
        let durationSeconds: Int?

        init(_ plan: RoutineSetPlan) {
            order = plan.order
            weightKg = plan.weightKg
            reps = plan.reps
            kindRaw = plan.kindRaw
            durationSeconds = plan.durationSeconds
        }

        func make() -> RoutineSetPlan {
            let plan = RoutineSetPlan(order: order, weightKg: weightKg, reps: reps)
            plan.kindRaw = kindRaw
            plan.durationSeconds = durationSeconds
            return plan
        }
    }

    struct EntryCopy: Equatable {
        let exercise: Exercise?
        let order: Int
        let notes: String
        let restSeconds: Int?
        let supersetGroup: Int?
        let plans: [PlanCopy]

        init(_ entry: RoutineExercise) {
            exercise = entry.exercise
            order = entry.order
            notes = entry.notes
            restSeconds = entry.restSeconds
            supersetGroup = entry.supersetGroup
            plans = entry.orderedSets.map(PlanCopy.init)
        }

        func insert(into routine: Routine, in context: ModelContext) {
            let entry = RoutineExercise(order: order)
            context.insert(entry)
            entry.exercise = exercise
            entry.notes = notes
            entry.restSeconds = restSeconds
            entry.supersetGroup = supersetGroup
            routine.exercises.append(entry)
            for copy in plans {
                let plan = copy.make()
                context.insert(plan)
                entry.sets.append(plan)
            }
        }

        static func == (lhs: EntryCopy, rhs: EntryCopy) -> Bool {
            let sameExercise: Bool = lhs.exercise?.persistentModelID == rhs.exercise?.persistentModelID
            let sameOrder: Bool = lhs.order == rhs.order && lhs.notes == rhs.notes
            let sameRest: Bool = lhs.restSeconds == rhs.restSeconds && lhs.supersetGroup == rhs.supersetGroup
            return sameExercise && sameOrder && sameRest && lhs.plans == rhs.plans
        }
    }

    let id: UUID
    let name: String
    let createdAt: Date
    let sectionRaw: String
    let categoryRaw: String
    let entries: [EntryCopy]

    init(_ routine: Routine) {
        id = routine.id
        name = routine.name
        createdAt = routine.createdAt
        sectionRaw = routine.sectionRaw
        categoryRaw = routine.categoryRaw
        entries = routine.orderedExercises.map(EntryCopy.init)
    }

    /// Inserts a new routine; the deleted object cannot be revived, so this rebuilds it.
    @discardableResult
    func restore(in context: ModelContext) -> Routine {
        let routine = Routine(name: name)
        routine.id = id
        routine.createdAt = createdAt
        routine.sectionRaw = sectionRaw
        routine.categoryRaw = categoryRaw
        context.insert(routine)
        for entry in entries {
            entry.insert(into: routine, in: context)
        }
        return routine
    }

    /// Puts a routine that is still alive back as it was, for Cancel in the builder: edits there
    /// apply as they're made, so without this a cancelled edit would quietly stick.
    func revert(_ routine: Routine, in context: ModelContext) {
        routine.name = name
        routine.sectionRaw = sectionRaw
        routine.categoryRaw = categoryRaw
        for entry in routine.exercises { context.delete(entry) }
        routine.exercises.removeAll()
        for entry in entries {
            entry.insert(into: routine, in: context)
        }
    }
}
