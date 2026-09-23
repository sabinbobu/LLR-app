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
private struct ExerciseSeed: Codable {
    let Name: String
    let Muscle: String
}

enum ExerciseLibrary {
    /// Pure parse step, kept separate from Bundle access so it's testable without a SwiftData container.
    static func parseSeeds(_ data: Data) throws -> [(name: String, muscle: String)] {
        try JSONDecoder().decode([ExerciseSeed].self, from: data).map { ($0.Name, $0.Muscle) }
    }

    private static func loadSeeds() -> [(name: String, muscle: String)] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seeds = try? parseSeeds(data)
        else { return [] }
        return seeds
    }

    /// Merges rather than gates on an empty table, so an upgrade that ships a larger library
    /// still fills in newly added exercises without touching what a user already logged.
    static func seedIfNeeded(_ context: ModelContext) {
        let existingNames = Set((try? context.fetch(FetchDescriptor<Exercise>()))?.map(\.name) ?? [])
        for (name, muscle) in loadSeeds() where !existingNames.contains(name) {
            context.insert(Exercise(name: name, muscleGroup: muscle))
        }
        try? context.save()
    }
}
