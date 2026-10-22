import Foundation

/// The derived text on a history card: muscle chips and the collapsed/expanded exercise rows.
struct WorkoutCardModel {
    static let previewLimit = 3
    static let chipLimit = 3

    struct Row: Equatable {
        let name: String
        let sets: Int
        let isWarmup: Bool
    }

    let rows: [Row]
    let chips: [String]

    init(workout: Workout) {
        var rows: [Row] = []
        var setsByMuscle: [String: Int] = [:]
        var muscleOrder: [String] = []
        for entry in workout.orderedExercises {
            let completed = entry.completedSets
            guard !completed.isEmpty else { continue }
            // A timed cardio/mobility opener is tagged warm-up by TimedWarmup; it is not "the work".
            let warmup = completed.allSatisfy { $0.kind == .warmup }
            rows.append(Row(name: entry.exercise?.name ?? "Exercise", sets: completed.count, isWarmup: warmup))
            guard !warmup, let muscle = entry.exercise?.muscleGroup else { continue }
            if setsByMuscle[muscle] == nil { muscleOrder.append(muscle) }
            setsByMuscle[muscle, default: 0] += completed.count
        }
        self.rows = rows
        // Stable on ties so the chips don't reshuffle between renders.
        let ranked = muscleOrder.enumerated().sorted { a, b in
            let (ca, cb) = (setsByMuscle[a.element] ?? 0, setsByMuscle[b.element] ?? 0)
            return ca != cb ? ca > cb : a.offset < b.offset
        }
        chips = ranked.prefix(Self.chipLimit).map(\.element)
    }

    /// Collapsed skips the warm-up so the preview shows real work; expanded is the whole session in order.
    func visibleRows(expanded: Bool) -> [Row] {
        expanded ? rows : Array(rows.filter { !$0.isWarmup }.prefix(Self.previewLimit))
    }

    var hiddenCount: Int { rows.count - visibleRows(expanded: false).count }
}
