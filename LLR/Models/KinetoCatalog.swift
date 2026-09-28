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
        case strength = "Strength"
        case mobility = "Mobility"
        case nerveMobility = "Nerve mobility"
        // Titled "Aerobic" (swimming and cycling belong here too), but the raw value stays
        // "Walking": user-made exercises store it and the bundled JSON uses it.
        case walking = "Walking"

        var id: Self { self }
        var title: String { self == .walking ? "Aerobic" : rawValue }
    }

    /// Codable and mutable so a user-made exercise can store and edit its own levels.
    struct Level: Codable, Hashable {
        var label: String
        var sets: Int?
        var reps: Int?
        var durationSeconds: Int?
        var notes: String?

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

    struct Source: Codable, Hashable {
        var title: String
        /// Optional: a physiotherapist's own prescription has no page to link to. Every bundled
        /// source has one (enforced by `KinetoCatalogTests`).
        var url: String?
        /// A string, not `SourceKind`, so the bundled JSON can use kinds the editor doesn't offer.
        var kind: String

        enum CodingKeys: String, CodingKey {
            case title = "Title", url = "Url", kind = "Kind"
        }
    }

    enum SourceKind: String, CaseIterable, Identifiable {
        case physiotherapist
        case patientEducation = "patient-education"
        case guideline
        case review
        case trial
        case labStudy = "lab-study"
        case other

        var id: Self { self }
        var title: String {
            switch self {
            case .physiotherapist: "My physiotherapist"
            case .patientEducation: "Patient leaflet"
            case .guideline: "Clinical guideline"
            case .review: "Systematic review"
            case .trial: "Trial"
            case .labStudy: "Lab study"
            case .other: "Other"
            }
        }
    }

    struct Exercise: Identifiable, Hashable {
        let name: String
        let category: Category
        let direction: Direction
        let levels: [Level]
        let mistakes: String?
        let cautions: String?
        let sources: [Source]
        /// Kineto's own how-to, never the gym library's, which can contradict a Kineto dose.
        var howto: [String] = []
        /// Nerve techniques: adding one first asks whether a physiotherapist prescribed it.
        var prescribedOnly = false

        var id: String { name }
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
        let PrescribedOnly: Bool?
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
                mistakes: $0.Mistakes, cautions: $0.Cautions, sources: $0.Sources,
                howto: $0.Howto ?? [], prescribedOnly: $0.PrescribedOnly ?? false
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

extension KinetoCatalog.Source {
    /// Only https links: the detail page opens them straight in the browser.
    static func isValidURL(_ text: String) -> Bool {
        guard text.hasPrefix("https://"), let url = URL(string: text) else { return false }
        return url.host() != nil
    }

    var hasValidURL: Bool { url.map(Self.isValidURL) ?? true }
    var link: URL? { url.flatMap { Self.isValidURL($0) ? URL(string: $0) : nil } }
    var isPrescription: Bool { kind == KinetoCatalog.SourceKind.physiotherapist.rawValue }
    var kindTitle: String { KinetoCatalog.SourceKind(rawValue: kind)?.title ?? kind }
}
