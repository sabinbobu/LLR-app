import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var notes: String
    /// Empty for workouts logged here (they're titled by time of day); imports keep their original name.
    var name: String = ""
    var sectionRaw: String = "gym"
    /// A label only (see SessionCategory); empty = uncategorised. Never read by history, prefill or PRs.
    var categoryRaw: String = ""
    // 0–10 each, back and leg scored separately; nil = not asked (every workout before Kineto shipped).
    var backPainBefore: Int?
    var legPainBefore: Int?
    var backPainAfter: Int?
    var legPainAfter: Int?
    /// Asked at check-out: did symptoms spread further down the leg during the session — the key
    /// disc warning sign a pain-score delta alone can miss.
    var symptomsSpread: Bool?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout) var exercises: [WorkoutExercise] = []

    init(startedAt: Date = .now) {
        self.id = UUID()
        self.startedAt = startedAt
        self.notes = ""
    }
}

extension Workout {
    var category: SessionCategory {
        get { SessionCategory(raw: categoryRaw) }
        set { categoryRaw = newValue.rawValue }
    }
    var section: WorkoutSection {
        get { WorkoutSection(rawValue: sectionRaw) ?? .gym }
        set { sectionRaw = newValue.rawValue }
    }

    /// Pain recorded on a session with no completed sets is the single most important data point
    /// Kineto can capture — stopping early because it hurt — so it must survive cleanup that would
    /// otherwise treat an empty workout as an abandoned draft.
    var hasPainRecorded: Bool {
        backPainBefore != nil || legPainBefore != nil || backPainAfter != nil || legPainAfter != nil
    }
}

@Model
final class WorkoutExercise {
    var workout: Workout?
    var exercise: Exercise?
    var order: Int
    /// Exercises of one workout that share a number are a superset; nil = done on its own.
    var supersetGroup: Int?
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
    /// Hold duration for a duration-based set (reps × seconds); nil = an ordinary weight/reps set.
    var durationSeconds: Int?
    /// Reps in reserve; nil = not rated. RPE is only ever a display of this (10 − rir), so a history
    /// that mixes both scales still averages on one.
    var rir: Double?

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

    var value: SetValue { SetValue(weightKg: weightKg, reps: reps, kind: kind, durationSeconds: durationSeconds, rir: rir) }
}

extension WorkoutExercise {
    var orderedSets: [SetEntry] { sets.sorted { $0.order < $1.order } }
    var completedSets: [SetEntry] { orderedSets.filter { $0.completedAt != nil } }
    var recoveryEntries: [MuscleRecovery.Entry] {
        guard let exercise else { return [] }
        return completedSets.filter(\.kind.countsTowardProgress).compactMap { set in
            guard let completedAt = set.completedAt else { return nil }
            return MuscleRecovery.Entry(
                exerciseName: exercise.name, muscle: exercise.muscleGroup,
                secondaryMuscles: exercise.secondaryMuscles, completedAt: completedAt, rir: set.rir
            )
        }
    }
    /// A card renders duration rows only once every set agrees, so a stray nil right after
    /// "Add Exercise" (before it inherits a value) never shows a mixed-up header.
    var isDurationBased: Bool { !sets.isEmpty && sets.allSatisfy { $0.durationSeconds != nil } }

    /// Aligned index-for-index with `orderedSets`; history is only sessions that started earlier,
    /// so re-opening an old workout shows the records it set at the time, not relative to today.
    func recordKinds() -> [Set<PersonalRecords.Kind>] {
        let sets = orderedSets
        guard let exercise, let workout else { return sets.map { _ in [] } }
        let history = exercise.sessions(excluding: workout, section: workout.section)
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
    var recoveryEntries: [MuscleRecovery.Entry] { exercises.flatMap(\.recoveryEntries) }
    var volumeKg: Double { completedSets.reduce(0) { $0 + $1.weightKg * Double($1.reps) } }
    var duration: TimeInterval { (endedAt ?? .now).timeIntervalSince(startedAt) }
    var summary: WorkoutSummary {
        var muscleSets: [String: Int] = [:]
        for entry in exercises {
            guard let group = entry.exercise?.muscleGroup else { continue }
            let working = entry.completedSets.filter(\.kind.countsTowardProgress).count
            if working > 0 { muscleSets[group, default: 0] += working }
        }
        return WorkoutSummary(
            date: startedAt,
            duration: duration,
            volumeKg: volumeKg,
            reps: completedSets.reduce(0) { $0 + $1.reps },
            muscleSets: muscleSets
        )
    }

    var recordSetCount: Int { exercises.reduce(0) { $0 + $1.recordKinds().filter { !$0.isEmpty }.count } }

    var title: String {
        if !name.isEmpty { return name }
        return switch Calendar.current.component(.hour, from: startedAt) {
        case 5..<12: "Morning Workout"
        case 12..<17: "Afternoon Workout"
        case 17..<22: "Evening Workout"
        default: "Night Workout"
        }
    }
}

extension Exercise {
    /// The in-progress workout is excluded so a set can never be pre-filled from itself. Scoped to
    /// one section so a gym Plank's history never prefills (or PRs against) a Kineto Plank, and vice versa.
    func sessions(excluding workout: Workout? = nil, section: WorkoutSection = .gym) -> [Session] {
        usages.compactMap { entry in
            guard let owner = entry.workout, owner.endedAt != nil, owner.id != workout?.id, owner.section == section
            else { return nil }
            let done = entry.completedSets.map(\.value)
            return done.isEmpty ? nil : Session(date: owner.startedAt, sets: done)
        }
    }
}
