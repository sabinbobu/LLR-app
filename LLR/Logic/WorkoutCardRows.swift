import Foundation

struct WorkoutCardRow: Identifiable, Equatable {
    let id: Int
    let name: String
    let sets: Int
    let isWarmup: Bool
}

extension Workout {
    /// Exercises that have a completed set, in workout order. A timed warm-up (every set tagged
    /// warm-up) is flagged so the card can mute it and keep it out of the collapsed preview.
    var cardRows: [WorkoutCardRow] {
        orderedExercises.enumerated().compactMap { index, entry in
            let done = entry.completedSets
            guard let name = entry.exercise?.name, !done.isEmpty else { return nil }
            return WorkoutCardRow(id: index, name: name, sets: done.count, isWarmup: done.allSatisfy { $0.kind == .warmup })
        }
    }

    /// Up to three muscle groups by working sets, ties in workout order. Cardio, Full Body and
    /// Other say how a lift trains rather than what it trains, so they are left out like on the body map.
    var cardMuscles: [String] {
        var sets: [String: Int] = [:]
        var firstSeen: [String] = []
        for entry in orderedExercises {
            guard let group = entry.exercise?.muscleGroup, MuscleGroup(rawValue: group)?.isTrainable ?? true else { continue }
            let working = entry.completedSets.filter(\.kind.countsTowardProgress).count
            guard working > 0 else { continue }
            if sets[group] == nil { firstSeen.append(group) }
            sets[group, default: 0] += working
        }
        let ranked = firstSeen.enumerated().sorted { a, b in
            let (x, y) = (sets[a.element] ?? 0, sets[b.element] ?? 0)
            return x != y ? x > y : a.offset < b.offset
        }
        return ranked.prefix(3).map(\.element)
    }
}
