import Foundation

/// The library lists equipment per exercise; an empty list means none is needed (bodyweight moves,
/// cardio), which reads better as "None" in a filter than as a blank.
enum Equipment {
    static let none = "None"

    /// The library's own vocabulary, offered for custom exercises so filters stay coherent.
    static let choices = ["Barbell", "Dumbbell", "Kettlebell", "Machine", "Plate", "Resistance Band", "Suspension", "Other"]

    static func label(_ equipment: [String]) -> String {
        equipment.isEmpty ? none : equipment.joined(separator: ", ")
    }

    /// Sorted, with "None" last so real equipment leads the menu.
    static func options(in all: [[String]]) -> [String] {
        let names = Set(all.flatMap { $0.isEmpty ? [none] : $0 })
        return names.sorted { ($0 == none ? 1 : 0, $0) < ($1 == none ? 1 : 0, $1) }
    }

    static func matches(_ equipment: [String], filter: String) -> Bool {
        filter == none ? equipment.isEmpty : equipment.contains(filter)
    }

    /// "Chest · Barbell"; with no equipment it's just the muscle, not "Chest · None".
    static func detail(muscle: String, equipment: [String]) -> String {
        equipment.isEmpty ? muscle : "\(muscle) · \(equipment.joined(separator: ", "))"
    }
}
