import Foundation
import SwiftData

/// Every field a user can set on their own exercise, gym or Kineto. Creating and editing share it,
/// so an edit can never forget a field that creation sets.
struct CustomExerciseDraft: Equatable {
    enum Problem: Equatable {
        case emptyName, duplicateName, noLevels, invalidSourceURL

        var message: String {
            switch self {
            case .emptyName: "Give the exercise a name."
            case .duplicateName: "An exercise with this name already exists."
            case .noLevels: "Add at least one level."
            case .invalidSourceURL: "Source links must start with https://."
            }
        }
    }

    var section: WorkoutSection
    var name = ""
    var muscleGroup = MuscleGroup.chest.rawValue
    var instructions: [String] = []
    var media: [ExerciseMediaItem] = []
    var secondaryMuscles: [String] = []
    var equipment: [String] = []
    var restSeconds: Int?
    // Gym only.
    var repRange: ClosedRange<Int>?
    // Kineto only.
    var kinetoCategory: KinetoCatalog.Category = .stability
    var kinetoDirection: KinetoCatalog.Direction = .neutral
    var kinetoLevels = [KinetoCatalog.Level(label: "Level 1", sets: 3, reps: 10, durationSeconds: nil, notes: nil)]
    var kinetoSources: [KinetoCatalog.Source] = []
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
        media = exercise.mediaItems
        secondaryMuscles = exercise.secondaryMuscles
        equipment = exercise.equipment
        restSeconds = exercise.restSeconds
        repRange = exercise.repRange
        kinetoCategory = exercise.kinetoCategoryRaw.flatMap(KinetoCatalog.Category.init) ?? .stability
        kinetoDirection = exercise.kinetoDirectionRaw.flatMap(KinetoCatalog.Direction.init) ?? .neutral
        kinetoLevels = exercise.kinetoLevels
        kinetoSources = exercise.kinetoSources
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
        if taken { return .duplicateName }
        guard section == .kineto else { return nil }
        if kinetoLevels.isEmpty { return .noLevels }
        if !kinetoSources.allSatisfy(\.hasValidURL) { return .invalidSourceURL }
        return nil
    }

    /// Writes the fields only; media rows are synced by the caller, which owns the model context.
    func apply(to exercise: Exercise) {
        exercise.name = trimmedName
        exercise.muscleGroup = muscleGroup
        exercise.sectionRaw = section.rawValue
        exercise.instructions = instructions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        exercise.secondaryMuscles = secondaryMuscles.filter { $0 != muscleGroup }
        exercise.equipment = equipment
        exercise.restSeconds = restSeconds
        switch section {
        case .gym:
            exercise.repRange = repRange
        case .kineto:
            exercise.kinetoCategoryRaw = kinetoCategory.rawValue
            exercise.kinetoDirectionRaw = kinetoDirection.rawValue
            exercise.kinetoLevels = kinetoLevels.enumerated().map { $1.cleaned(fallbackLabel: "Level \($0 + 1)") }
            exercise.kinetoSources = kinetoSources.compactMap(\.cleaned)
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

    /// Files go only after the rows are saved away: a failed save must not leave rows whose files are gone.
    func deleteWithMedia(from context: ModelContext) {
        let files = media.map(\.fileName)
        context.delete(self)
        do {
            try context.save()
        } catch {
            context.rollback()
            return
        }
        for file in files { ExerciseMediaStore.delete(file) }
    }

    /// A row saved before levels existed has just the single legacy dose, so it reads as one level.
    var kinetoLevels: [KinetoCatalog.Level] {
        get {
            if let data = kinetoLevelsData,
               let levels = try? JSONDecoder().decode([KinetoCatalog.Level].self, from: data), !levels.isEmpty {
                return levels
            }
            return [KinetoCatalog.Level(
                label: "Your dose", sets: kinetoSets, reps: kinetoReps, durationSeconds: kinetoDurationSeconds, notes: nil
            )]
        }
        set {
            kinetoLevelsData = try? JSONEncoder().encode(newValue)
            // Levels replace the legacy dose; clearing it leaves one source of truth.
            kinetoSets = nil
            kinetoReps = nil
            kinetoDurationSeconds = nil
        }
    }

    var kinetoSources: [KinetoCatalog.Source] {
        get { kinetoSourcesData.flatMap { try? JSONDecoder().decode([KinetoCatalog.Source].self, from: $0) } ?? [] }
        set { kinetoSourcesData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue) }
    }

    /// A user-made Kineto exercise in the catalog's own shape, so its detail page and the add-at-a-dose
    /// flow are the same code as the cited entries.
    var customKinetoSpec: KinetoCatalog.Exercise? {
        guard isCustomKineto else { return nil }
        return KinetoCatalog.Exercise(
            name: name,
            category: kinetoCategoryRaw.flatMap(KinetoCatalog.Category.init) ?? .stability,
            direction: kinetoDirectionRaw.flatMap(KinetoCatalog.Direction.init) ?? .neutral,
            levels: kinetoLevels, mistakes: kinetoMistakes, cautions: kinetoCautions, sources: kinetoSources,
            howto: instructions
        )
    }
}

extension KinetoCatalog.Level {
    /// Zero or negative counts would log empty sets, so they mean "doesn't apply", like a blank field.
    func cleaned(fallbackLabel: String) -> Self {
        let positive: (Int?) -> Int? = { $0.flatMap { $0 > 0 ? $0 : nil } }
        return Self(
            label: label.nilIfBlank ?? fallbackLabel, sets: positive(sets), reps: positive(reps),
            durationSeconds: positive(durationSeconds), notes: notes?.nilIfBlank
        )
    }
}

extension KinetoCatalog.Source {
    /// nil when there's nothing to show; a link with no title falls back to the link itself.
    var cleaned: Self? {
        let link = url?.nilIfBlank
        guard let title = title.nilIfBlank ?? link else { return nil }
        return Self(title: title, url: link, kind: kind)
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
