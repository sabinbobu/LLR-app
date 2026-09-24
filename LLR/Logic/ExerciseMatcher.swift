import Foundation

/// Maps an imported exercise name onto one LLR already knows. Exact (case-insensitive) first; then
/// Strong-style "Clean (Barbell)" onto a library "Clean" — but only when that entry lists the same
/// equipment, so "Push Up (Weighted)" never folds into bodyweight Push Up and mixes their records.
enum ExerciseMatcher {
    struct Candidate {
        let name: String
        let equipment: [String]
    }

    static func match(_ name: String, in candidates: [Candidate]) -> Int? {
        let key = name.lowercased()
        if let exact = candidates.firstIndex(where: { $0.name.lowercased() == key }) {
            return exact
        }
        guard name.hasSuffix(")"), let open = name.lastIndex(of: "(") else { return nil }
        let base = name[..<open].trimmingCharacters(in: .whitespaces).lowercased()
        let qualifier = name[name.index(after: open)..<name.index(before: name.endIndex)]
        return candidates.firstIndex {
            $0.name.lowercased() == base && $0.equipment.contains { $0.caseInsensitiveCompare(qualifier) == .orderedSame }
        }
    }
}
