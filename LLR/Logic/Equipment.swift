import Foundation

/// The seed data has no explicit equipment field; it's encoded as a trailing "(Barbell)" etc.
/// in the exercise name. Extracting it here keeps that convention in one place instead of
/// scattered regexes, and degrades to "Other" for names that don't follow it.
enum Equipment {
    // Longer, more specific names first: "Smith Machine" must win over the shorter "Machine".
    static let known = [
        "Smith Machine", "Trap Bar", "EZ Bar", "Barbell", "Dumbbell", "Cable", "Machine",
        "Band", "Kettlebell", "Suspension", "Bodyweight", "Plate",
    ]

    static func tag(for exerciseName: String) -> String {
        guard let open = exerciseName.lastIndex(of: "("), let close = exerciseName.lastIndex(of: ")"), open < close else {
            return "Other"
        }
        let inner = String(exerciseName[exerciseName.index(after: open)..<close])
        return known.first { inner.localizedCaseInsensitiveContains($0) } ?? "Other"
    }

    static func allTags(in names: [String]) -> [String] {
        Array(Set(names.map(tag(for:)))).sorted()
    }
}
