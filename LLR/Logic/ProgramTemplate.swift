import Foundation

/// A set as a plan prescribes it: a blank weight means "use what you lifted last time".
struct PlannedSet: Equatable {
    var weightKg: Double?
    var reps: Int?
    var kind: SetKind = .normal
    /// Hold duration for a duration-based set (reps × seconds); nil = an ordinary weight/reps set.
    var durationSeconds: Int? = nil
}

extension SetKind: Decodable {}

/// A published program from the bundled library: one or more days, each of which becomes a routine.
struct ProgramTemplate: Decodable, Identifiable, Hashable {
    enum Goal: String, Decodable, CaseIterable, Identifiable {
        case strength, muscle, athletic, conditioning, bodyweight, glutes

        var id: Self { self }

        var title: String {
            switch self {
            case .strength: "Strength"
            case .muscle: "Muscle"
            case .athletic: "Athletic"
            case .conditioning: "Conditioning"
            case .bodyweight: "Bodyweight"
            case .glutes: "Glutes"
            }
        }
    }

    enum Level: String, Decodable, CaseIterable, Identifiable {
        case beginner, intermediate, advanced

        var id: Self { self }
        var title: String { rawValue.capitalized }
    }

    enum Gear: String, Decodable, CaseIterable, Identifiable {
        case barbell, fullGym, dumbbells, kettlebell, bodyweight

        var id: Self { self }

        var title: String {
            switch self {
            case .barbell: "Barbell"
            case .fullGym: "Full gym"
            case .dumbbells: "Dumbbells"
            case .kettlebell: "Kettlebell"
            case .bodyweight: "Bodyweight"
            }
        }
    }

    struct Day: Decodable, Hashable, Identifiable {
        let name: String
        let exercises: [Entry]

        var id: String { name }
    }

    struct Entry: Decodable, Hashable {
        /// The exact exercise name in the bundled exercise library.
        let exercise: String
        let sets: [SetGroup]
        let rest: Int?
        let notes: String?
    }

    struct SetGroup: Decodable, Hashable {
        let count: Int?
        /// nil = as many as possible, with no target.
        let reps: Int?
        let repsMax: Int?
        let kind: SetKind?
    }

    let id: String
    let name: String
    let author: String
    let goal: Goal
    let level: Level
    let equipment: Gear
    let daysPerWeek: Int
    let summary: String
    let schedule: String
    let progression: String
    let source: String
    let sourceURL: String?
    let routines: [Day]
}

extension ProgramTemplate.SetGroup {
    var sets: Int { max(count ?? 1, 1) }

    /// "3 × 5", "3 × 8–12", "1 × 5+" (as many as possible past 5), "3 × max", "2 × 5 warm-up".
    var text: String {
        let target: String
        if let reps {
            target = repsMax.map { "\(reps)–\($0)" } ?? "\(reps)"
        } else {
            target = "max"
        }
        let amrap = kind == .failure && reps != nil ? "+" : ""
        let label = switch kind ?? .normal {
        case .warmup: " warm-up"
        case .drop: " drop"
        case .normal, .failure: ""
        }
        return "\(sets) × \(target)\(amrap)\(label)"
    }
}

extension ProgramTemplate.Entry {
    /// A range's bottom becomes the planned reps: the first session at a weight aims low,
    /// then the lifter works up to the top before adding load.
    var plannedSets: [PlannedSet] {
        sets.flatMap { group in
            Array(repeating: PlannedSet(weightKg: nil, reps: group.reps, kind: group.kind ?? .normal), count: group.sets)
        }
    }

    var setsText: String {
        sets.map(\.text).joined(separator: " + ")
    }

    /// A single planned rep count can't hold a range, so the range travels in the routine's notes.
    var routineNotes: String {
        let ranges = sets.compactMap { group in group.repsMax.map { "\(group.reps ?? 0)–\($0)" } }
        let range = Set(ranges).count == 1 ? ranges.first.map { "Aim for \($0) reps" } : nil
        return [range, notes].compactMap { $0 }.joined(separator: " · ")
    }
}
