import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: String
    var isCustom: Bool
    @Relationship(inverse: \WorkoutExercise.exercise) var usages: [WorkoutExercise] = []

    init(name: String, muscleGroup: String, isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.isCustom = isCustom
    }
}

@Model
final class Workout {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout) var exercises: [WorkoutExercise] = []

    init(startedAt: Date = .now) {
        self.id = UUID()
        self.startedAt = startedAt
        self.notes = ""
    }
}

@Model
final class WorkoutExercise {
    var workout: Workout?
    var exercise: Exercise?
    var order: Int
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.workoutExercise) var sets: [SetEntry] = []

    init(order: Int) {
        self.order = order
    }
}

@Model
final class SetEntry {
    var workoutExercise: WorkoutExercise?
    var order: Int
    var weightKg: Double
    var reps: Int
    var completedAt: Date?

    init(order: Int, weightKg: Double, reps: Int) {
        self.order = order
        self.weightKg = weightKg
        self.reps = reps
    }
}

extension SetEntry {
    var value: SetValue { SetValue(weightKg: weightKg, reps: reps) }
}

extension WorkoutExercise {
    var orderedSets: [SetEntry] { sets.sorted { $0.order < $1.order } }
    var completedSets: [SetEntry] { orderedSets.filter { $0.completedAt != nil } }
}

extension Workout {
    var orderedExercises: [WorkoutExercise] { exercises.sorted { $0.order < $1.order } }
    var completedSets: [SetEntry] { exercises.flatMap(\.completedSets) }
    var volumeKg: Double { completedSets.reduce(0) { $0 + $1.weightKg * Double($1.reps) } }
    var duration: TimeInterval { (endedAt ?? .now).timeIntervalSince(startedAt) }

    var title: String {
        switch Calendar.current.component(.hour, from: startedAt) {
        case 5..<12: "Morning Workout"
        case 12..<17: "Afternoon Workout"
        case 17..<22: "Evening Workout"
        default: "Night Workout"
        }
    }
}

extension Exercise {
    /// The in-progress workout is excluded so a set can never be pre-filled from itself.
    func sessions(excluding workout: Workout? = nil) -> [Session] {
        usages.compactMap { entry in
            guard let owner = entry.workout, owner.endedAt != nil, owner.id != workout?.id else { return nil }
            let done = entry.completedSets.map(\.value)
            return done.isEmpty ? nil : Session(date: owner.startedAt, sets: done)
        }
    }
}
