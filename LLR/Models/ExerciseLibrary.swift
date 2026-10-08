import Foundation
import SwiftData

enum MuscleGroup: String, CaseIterable, Identifiable {
    case abdominals = "Abdominals"
    case abductors = "Abductors"
    case adductors = "Adductors"
    case biceps = "Biceps"
    case calves = "Calves"
    case cardio = "Cardio"
    case chest = "Chest"
    case forearms = "Forearms"
    case fullBody = "Full Body"
    case glutes = "Glutes"
    case hamstrings = "Hamstrings"
    case lats = "Lats"
    case lowerBack = "Lower Back"
    case neck = "Neck"
    case other = "Other"
    case quadriceps = "Quadriceps"
    case shoulders = "Shoulders"
    case traps = "Traps"
    case triceps = "Triceps"
    case upperBack = "Upper Back"

    var id: String { rawValue }
}

/// Matches the field names in the bundled exercises.json seed file (capitalized, no relation to Swift style).
private struct ExerciseSeed: Decodable {
    let Name: String
    let Muscle: String
    let Primary: String?
    let Equipment: [String]?
    let Secondary: [String]?
    let Howto: [String]?
}

/// One bundled library entry, kept apart from the SwiftData model so parsing is testable without a container.
struct LibraryExercise: Equatable {
    let name: String
    let muscle: String
    let equipment: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
}

enum ExerciseLibrary {
    static func parseSeeds(_ data: Data) throws -> [LibraryExercise] {
        try JSONDecoder().decode([ExerciseSeed].self, from: data).map { seed in
            LibraryExercise(
                name: seed.Name,
                muscle: seed.Primary ?? seed.Muscle,
                equipment: seed.Equipment ?? [],
                secondaryMuscles: seed.Secondary ?? [],
                instructions: seed.Howto ?? []
            )
        }
    }

    private static func loadSeeds() -> [LibraryExercise] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seeds = try? parseSeeds(data)
        else { return [] }
        return seeds
    }

    /// The seed opens with a curated "popular" block, then restarts A–Z with the full library;
    /// the block ends where that alphabetical order resets. A plain A–Z file has no block.
    static func popularNames(in names: [String]) -> [String] {
        guard let reset = names.indices.dropFirst().first(where: {
            names[$0].localizedStandardCompare(names[$0 - 1]) == .orderedAscending
        }) else { return [] }
        return Array(names[..<reset])
    }

    static let popular: [String] = popularNames(in: loadSeeds().map(\.name))

    /// One merged sync, not two: seeding gym and Kineto lists separately would duplicate or
    /// flip-flop rows a name appears in both places for (every ★ Kineto exercise), since each
    /// call only ever sees its own list's fields.
    static func seedIfNeeded(_ context: ModelContext) {
        let gym = loadSeeds()
        let gymNames = Set(gym.map(\.name))
        let kinetoOnly = KinetoCatalog.libraryEntries.filter { !gymNames.contains($0.name) }
        sync(gym + kinetoOnly, into: context)
    }

    /// Refreshes built-in rows in place (matched by name) and inserts new ones, so an upgrade that
    /// ships new fields or exercises reaches existing installs without touching logged history.
    /// Custom exercises belong to the user and are never overwritten, even on a name clash.
    static func sync(_ library: [LibraryExercise], into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let takenNames = Set(existing.map(\.name))
        var builtIns: [String: Exercise] = [:]
        for exercise in existing where !exercise.isCustom {
            builtIns[exercise.name] = exercise
        }
        for entry in library {
            if let exercise = builtIns[entry.name] {
                exercise.update(from: entry)
            } else if !takenNames.contains(entry.name) {
                let exercise = Exercise(name: entry.name, muscleGroup: entry.muscle)
                exercise.update(from: entry)
                context.insert(exercise)
            }
        }
        try? context.save()
    }
}

extension Exercise {
    /// Assigns only what differs, so a launch with an unchanged library leaves the store clean.
    func update(from entry: LibraryExercise) {
        if muscleGroup != entry.muscle { muscleGroup = entry.muscle }
        if equipment != entry.equipment { equipment = entry.equipment }
        if secondaryMuscles != entry.secondaryMuscles { secondaryMuscles = entry.secondaryMuscles }
        if instructions != entry.instructions { instructions = entry.instructions }
    }

    var detail: String { Equipment.detail(muscle: muscleGroup, equipment: equipment) }

    var repRange: ClosedRange<Int>? {
        get {
            guard let low = repRangeMin, let high = repRangeMax, low <= high else { return nil }
            return low...high
        }
        set {
            repRangeMin = newValue?.lowerBound
            repRangeMax = newValue?.upperBound
        }
    }

    /// nil = no progression: sets prefill with last session's values unchanged.
    func progression(unit: WeightUnit) -> Progression.Config? {
        let rule = Progression.Rule(rawValue: progressionRuleRaw) ?? .double
        let step = progressionStepKg ?? Progression.incrementKg(equipment: equipment, unit: unit)
        let assisted = ExerciseProgress.isAssisted(name: name)
        if rule == .time { return Progression.Config(rule: .time, range: 1...1, incrementKg: step, assisted: assisted) }
        guard let range = repRange else { return nil }
        // The exercise editor can still write a range under a fixed-reps rule: its top is the target.
        let reps = rule == .double ? range : range.upperBound...range.upperBound
        return Progression.Config(rule: rule, range: reps, incrementKg: step, assisted: assisted)
    }

    func setProgression(_ rule: Progression.Rule?, range: ClosedRange<Int>?) {
        progressionRuleRaw = rule?.rawValue ?? ""
        repRange = range
    }

    func progressionPrefill(index: Int, history: [Session], currentLast: SetValue?) -> SetValue? {
        Progression.prefill(index: index, history: history, currentLast: currentLast, config: progression(unit: .stored))
    }
}
