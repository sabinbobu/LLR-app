import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var name: String
    var createdAt: Date
    var sectionRaw: String = "gym"
    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine) var exercises: [RoutineExercise] = []

    init(name: String = "") {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
    }
}

extension Routine {
    var section: WorkoutSection {
        get { WorkoutSection(rawValue: sectionRaw) ?? .gym }
        set { sectionRaw = newValue.rawValue }
    }
}

@Model
final class RoutineExercise {
    var routine: Routine?
    var exercise: Exercise?
    var order: Int
    var notes: String
    /// nil = no automatic rest for this exercise (the routine default from the reference screens).
    var restSeconds: Int?
    @Relationship(deleteRule: .cascade, inverse: \RoutineSetPlan.routineExercise) var sets: [RoutineSetPlan] = []

    init(order: Int) {
        self.order = order
        self.notes = ""
    }
}

@Model
final class RoutineSetPlan {
    var routineExercise: RoutineExercise?
    var order: Int
    /// nil = left blank on purpose ("leave it blank to workout on the go"), not zero.
    var weightKg: Double?
    var reps: Int?
    var kindRaw: String = "normal"
    /// Hold duration for a duration-based plan (reps × seconds); nil = an ordinary weight/reps set.
    var durationSeconds: Int?

    init(order: Int, weightKg: Double? = nil, reps: Int? = nil) {
        self.order = order
        self.weightKg = weightKg
        self.reps = reps
    }

    var kind: SetKind {
        get { SetKind(rawValue: kindRaw) ?? .normal }
        set { kindRaw = newValue.rawValue }
    }
}

extension Routine {
    var orderedExercises: [RoutineExercise] { exercises.sorted { $0.order < $1.order } }
}

extension RoutineExercise {
    var orderedSets: [RoutineSetPlan] { sets.sorted { $0.order < $1.order } }
    /// A card renders duration rows only once every plan agrees, so a stray nil right after
    /// "Add set" (before it inherits a value) never shows a mixed-up header.
    var isDurationBased: Bool { !sets.isEmpty && sets.allSatisfy { $0.durationSeconds != nil } }
}
