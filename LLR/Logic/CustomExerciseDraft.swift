import Foundation
import SwiftData

/// Every field a user can set on their own exercise, gym or Kineto. Creating and editing share it,
/// so an edit can never forget a field that creation sets.
struct CustomExerciseDraft: Equatable {
    enum Problem: Equatable {
        case emptyName, duplicateName

        var message: String {
            switch self {
            case .emptyName: "Give the exercise a name."
            case .duplicateName: "An exercise with this name already exists."
            }
        }
    }

    var section: WorkoutSection
    var name = ""
    var muscleGroup = MuscleGroup.chest.rawValue
    var instructions: [String] = []
    var media: [ExerciseMediaItem] = []
    // Gym only.
    var secondaryMuscles: [String] = []
    var equipment: [String] = []
    var restSeconds: Int?
    var repRange: ClosedRange<Int>?
    // Kineto only.
    var kinetoCategory: KinetoCatalog.Category = .stability
    var kinetoDirection: KinetoCatalog.Direction = .neutral
    var kinetoSets: Int? = 3
    var kinetoReps: Int? = 10
    var kinetoDurationSeconds: Int?
    var kinetoMistakes = ""
    var kinetoCautions = ""

    init(section: WorkoutSection, name: String = "") {
        self.section = section
        self.name = name
        if section == .kineto { muscleGroup = MuscleGroup.abdominals.rawValue }
    }

    init(_ exercise: Exercise) {
        section = WorkoutSection(rawValue: exercise.sectionRaw) ?? .gym
        name = exercise.name
        muscleGroup = exercise.muscleGroup
        instructions = exercise.instructions
        media = exercise.media.sorted { $0.createdAt < $1.createdAt }.map(\.item)
        secondaryMuscles = exercise.secondaryMuscles
        equipment = exercise.equipment
        restSeconds = exercise.restSeconds
        repRange = exercise.repRange
        kinetoCategory = exercise.kinetoCategoryRaw.flatMap(KinetoCatalog.Category.init) ?? .stability
        kinetoDirection = exercise.kinetoDirectionRaw.flatMap(KinetoCatalog.Direction.init) ?? .neutral
        kinetoSets = exercise.kinetoSets
        kinetoReps = exercise.kinetoReps
        kinetoDurationSeconds = exercise.kinetoDurationSeconds
        kinetoMistakes = exercise.kinetoMistakes ?? ""
        kinetoCautions = exercise.kinetoCautions ?? ""
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Names must be unique: `RoutineLibrary.exercisesByName` prefers a built-in on a clash, so a
    /// duplicate would silently log against the wrong exercise.
    func problem(existingNames: [String], originalName: String? = nil) -> Problem? {
        guard !trimmedName.isEmpty else { return .emptyName }
        let taken = existingNames.contains {
            $0.caseInsensitiveCompare(trimmedName) == .orderedSame
                && $0.caseInsensitiveCompare(originalName ?? "") != .orderedSame
        }
        return taken ? .duplicateName : nil
    }

    /// Writes the fields only; media rows are synced by the caller, which owns the model context.
    func apply(to exercise: Exercise) {
        exercise.name = trimmedName
        exercise.muscleGroup = muscleGroup
        exercise.sectionRaw = section.rawValue
        exercise.instructions = instructions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        switch section {
        case .gym:
            exercise.secondaryMuscles = secondaryMuscles.filter { $0 != muscleGroup }
            exercise.equipment = equipment
            exercise.restSeconds = restSeconds
            exercise.repRange = repRange
        case .kineto:
            exercise.kinetoCategoryRaw = kinetoCategory.rawValue
            exercise.kinetoDirectionRaw = kinetoDirection.rawValue
            exercise.kinetoSets = kinetoSets
            exercise.kinetoReps = kinetoReps
            exercise.kinetoDurationSeconds = kinetoDurationSeconds
            exercise.kinetoMistakes = kinetoMistakes.nilIfBlank
            exercise.kinetoCautions = kinetoCautions.nilIfBlank
        }
    }
}

extension Exercise {
    var isCustomKineto: Bool { isCustom && sectionRaw == WorkoutSection.kineto.rawValue }

    /// Only a custom exercise never logged: `usages` nullify on delete, which would leave past
    /// workouts with nameless entries.
    var canDelete: Bool { isCustom && usages.isEmpty }

    func deleteWithMedia(from context: ModelContext) {
        for item in media { ExerciseMediaStore.delete(item.fileName) }
        context.delete(self)
    }

    /// A user-made Kineto exercise in the catalog's own shape, so its detail page and the add-at-a-dose
    /// flow are the same code as the cited entries. It has no sources, and says so where it's shown.
    var customKinetoSpec: KinetoCatalog.Exercise? {
        guard isCustomKineto else { return nil }
        let level = KinetoCatalog.Level(
            label: "Your dose", sets: kinetoSets, reps: kinetoReps,
            durationSeconds: kinetoDurationSeconds, notes: nil
        )
        return KinetoCatalog.Exercise(
            name: name,
            category: kinetoCategoryRaw.flatMap(KinetoCatalog.Category.init) ?? .stability,
            direction: kinetoDirectionRaw.flatMap(KinetoCatalog.Direction.init) ?? .neutral,
            levels: [level], mistakes: kinetoMistakes, cautions: kinetoCautions, sources: []
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
