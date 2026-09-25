import Foundation

/// The bundled physiotherapy exercise catalog: dosing, cautions and cited sources for Kineto.
/// A new exercise (no gym-library counterpart) also carries base library fields so
/// `ExerciseLibrary.seedIfNeeded` can create its `Exercise` row from `libraryEntries`. A name
/// already in the gym library (marked ★ in the plan) carries only the fields below, so seeding
/// never touches that row's library fields.
enum KinetoCatalog {
    enum Direction: String, Decodable, Hashable {
        // `extension` is a Swift keyword, so the case needs backticks; the raw value (and the
        // JSON) stays the plain word.
        case flexion, `extension`, rotation, neutral

        var title: String {
            switch self {
            case .flexion: "Flexion"
            case .extension: "Extension"
            case .rotation: "Rotation"
            case .neutral: "Neutral"
            }
        }
    }

    enum Category: String, Decodable, Hashable, CaseIterable, Identifiable {
        case stability = "Stability & endurance"
        case mobility = "Mobility"
        case walking = "Walking"

        var id: Self { self }
        var title: String { rawValue }
    }

    struct Level: Decodable, Hashable {
        let label: String
        let sets: Int?
        let reps: Int?
        let durationSeconds: Int?
        let notes: String?

        enum CodingKeys: String, CodingKey {
            case label = "Label", sets = "Sets", reps = "Reps", durationSeconds = "DurationSeconds", notes = "Notes"
        }

        /// "5 × 15 s", "2 × 10 × 2 s", "1 × 15" — physio sets the exact numbers; this is guidance.
        var doseText: String {
            switch (sets, reps, durationSeconds) {
            case let (sets?, nil, duration?): "\(sets) × \(duration) s"
            case let (sets?, reps?, duration?): "\(sets) × \(reps) × \(duration) s"
            case let (sets?, reps?, nil): "\(sets) × \(reps)"
            case let (nil, reps?, nil): "\(reps) reps"
            case let (nil, nil, duration?): Format.duration(TimeInterval(duration))
            default: "Set by your physiotherapist"
            }
        }
    }

    struct Source: Decodable, Hashable {
        let title: String
        let url: String
        let kind: String

        enum CodingKeys: String, CodingKey {
            case title = "Title", url = "Url", kind = "Kind"
        }
    }

    struct Exercise: Decodable, Identifiable, Hashable {
        let name: String
        let category: Category
        let direction: Direction
        let levels: [Level]
        let mistakes: String?
        let cautions: String?
        let sources: [Source]

        var id: String { name }

        enum CodingKeys: String, CodingKey {
            case name = "Name", category = "Category", direction = "Direction", levels = "Levels",
                 mistakes = "Mistakes", cautions = "Cautions", sources = "Sources"
        }
    }

    /// Matches the shape of a gym-library seed, but every base field is optional: a ★ name
    /// (already in exercises.json) carries none of them, only the Kineto-specific fields.
    private struct Seed: Decodable {
        let Name: String
        let Muscle: String?
        let Primary: String?
        let Equipment: [String]?
        let Secondary: [String]?
        let Howto: [String]?
        let Category: Category
        let Direction: Direction
        let Levels: [Level]
        let Mistakes: String?
        let Cautions: String?
        let Sources: [Source]
    }

    private struct File: Decodable {
        let version: Int
        let exercises: [Seed]
    }

    static func parse(_ data: Data) throws -> (exercises: [Exercise], libraryEntries: [LibraryExercise]) {
        let file = try JSONDecoder().decode(File.self, from: data)
        let exercises = file.exercises.map {
            Exercise(
                name: $0.Name, category: $0.Category, direction: $0.Direction, levels: $0.Levels,
                mistakes: $0.Mistakes, cautions: $0.Cautions, sources: $0.Sources
            )
        }
        let libraryEntries = file.exercises.compactMap { seed -> LibraryExercise? in
            guard let muscle = seed.Primary ?? seed.Muscle else { return nil }
            return LibraryExercise(
                name: seed.Name, muscle: muscle, equipment: seed.Equipment ?? [],
                secondaryMuscles: seed.Secondary ?? [], instructions: seed.Howto ?? []
            )
        }
        return (exercises, libraryEntries)
    }

    private static let loaded: (version: Int, exercises: [Exercise], libraryEntries: [LibraryExercise]) = {
        guard let url = Bundle.main.url(forResource: "kineto_exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data),
              let parsed = try? parse(data)
        else { return (0, [], []) }
        return (file.version, parsed.exercises, parsed.libraryEntries)
    }()

    /// Bumped whenever the catalog content changes, so the physio-clearance gate can re-ask.
    static var version: Int { loaded.version }
    static var exercises: [Exercise] { loaded.exercises }
    static var libraryEntries: [LibraryExercise] { loaded.libraryEntries }

    static func exercise(named name: String) -> Exercise? {
        exercises.first { $0.name == name }
    }
}
