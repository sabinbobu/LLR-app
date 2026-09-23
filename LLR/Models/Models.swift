import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: String
    var isCustom: Bool
    /// nil = use the global default; 0 = no rest timer for this exercise.
    var restSeconds: Int?
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
    // Stored as a raw string with a default so existing stores migrate without a schema version bump.
    var kindRaw: String = "normal"

    init(order: Int, weightKg: Double, reps: Int) {
        self.order = order
        self.weightKg = weightKg
        self.reps = reps
    }
}

extension SetEntry {
    var kind: SetKind {
        get { SetKind(rawValue: kindRaw) ?? .normal }
        set { kindRaw = newValue.rawValue }
    }

    var value: SetValue { SetValue(weightKg: weightKg, reps: reps, kind: kind) }
}

extension WorkoutExercise {
    var orderedSets: [SetEntry] { sets.sorted { $0.order < $1.order } }
    var completedSets: [SetEntry] { orderedSets.filter { $0.completedAt != nil } }

    /// Aligned index-for-index with `orderedSets`; history is only sessions that started earlier,
    /// so re-opening an old workout shows the records it set at the time, not relative to today.
    func recordKinds() -> [Set<PersonalRecords.Kind>] {
        let sets = orderedSets
        guard let exercise, let workout else { return sets.map { _ in [] } }
        let history = exercise.sessions(excluding: workout)
            .filter { $0.date < workout.startedAt }
            .flatMap(\.sets)
        var earlier: [SetValue] = []
        return sets.map { set in
            guard set.completedAt != nil else { return [] }
            let kinds = PersonalRecords.kinds(for: set.value, history: history, earlierToday: earlier)
            earlier.append(set.value)
            return kinds
        }
    }
}

extension Workout {
    var orderedExercises: [WorkoutExercise] { exercises.sorted { $0.order < $1.order } }
    var completedSets: [SetEntry] { exercises.flatMap(\.completedSets) }
    var volumeKg: Double { completedSets.reduce(0) { $0 + $1.weightKg * Double($1.reps) } }
    var duration: TimeInterval { (endedAt ?? .now).timeIntervalSince(startedAt) }
    var recordSetCount: Int { exercises.reduce(0) { $0 + $1.recordKinds().filter { !$0.isEmpty }.count } }

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
