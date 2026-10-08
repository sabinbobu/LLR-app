import Foundation

/// Exercises done back to back: one set of each, then the rest. Membership is a shared number
/// on the workout's exercises; everything here works on plain values so the flow is testable.
/// A round is one set index across the group, so exercises with different set counts simply
/// drop out of the later rounds.
enum Superset {
    struct Member: Equatable {
        var group: Int?
        var completed: [Bool]
    }

    struct Position: Equatable {
        let exercise: Int
        let set: Int
    }

    struct Tag: Equatable {
        let letter: String
        let position: Int
        let count: Int
    }

    /// Pairs an exercise with the one after it, joining whichever group either is already in.
    static func pairing(_ groups: [Int?], at index: Int) -> [Int?] {
        guard groups.indices.contains(index), index + 1 < groups.count else { return groups }
        let next = index + 1
        let group = groups[index] ?? groups[next] ?? (groups.compactMap { $0 }.max() ?? 0) + 1
        var result = groups
        // Two exercises that each sit in a group make one group of all of them.
        if let absorbed = groups[next], absorbed != group {
            result = result.map { $0 == absorbed ? group : $0 }
        }
        result[index] = group
        result[next] = group
        return result
    }

    static func unpairing(_ groups: [Int?], at index: Int) -> [Int?] {
        guard groups.indices.contains(index), let group = groups[index] else { return groups }
        var result = groups
        result[index] = nil
        // One exercise is not a superset.
        if result.filter({ $0 == group }).count < 2 {
            result = result.map { $0 == group ? nil : $0 }
        }
        return result
    }

    /// Whether ticking this set finishes its round: nobody else in the group still owes that
    /// set. That is when the rest starts; until then the next exercise follows straight on.
    static func endsRound(_ members: [Member], exercise: Int, set: Int) -> Bool {
        guard members.indices.contains(exercise), let group = members[exercise].group else { return true }
        return !members.enumerated().contains { index, member in
            index != exercise && member.group == group && set < member.completed.count && !member.completed[set]
        }
    }

    /// The set a lifter is about to do: the first unticked one in workout order, except that
    /// inside a superset it is the earliest round anyone still owes.
    static func next(in members: [Member]) -> Position? {
        guard let first = members.firstIndex(where: { $0.completed.contains(false) }) else { return nil }
        let owing = members.enumerated()
            .filter { members[first].group == nil ? $0.offset == first : $0.element.group == members[first].group }
            .compactMap { index, member in member.completed.firstIndex(of: false).map { Position(exercise: index, set: $0) } }
        guard let round = owing.map(\.set).min() else { return nil }
        return owing.first { $0.set == round }
    }

    /// "A" for the first superset in the workout, "B" for the next; nil outside one.
    static func tags(_ groups: [Int?]) -> [Tag?] {
        let counts = Dictionary(grouping: groups.compactMap { $0 }, by: { $0 }).mapValues(\.count)
        var letters: [Int: String] = [:]
        var seen: [Int: Int] = [:]
        return groups.map { group in
            guard let group, let count = counts[group], count > 1 else { return nil }
            let letter = letters[group] ?? String(UnicodeScalar(UInt8(65 + letters.count % 26)))
            letters[group] = letter
            seen[group, default: 0] += 1
            return Tag(letter: letter, position: seen[group] ?? 1, count: count)
        }
    }
}
