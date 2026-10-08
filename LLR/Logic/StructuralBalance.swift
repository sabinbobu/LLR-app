import Foundation

/// Strength ratios between lifts: each lift's best estimated one-rep max as a percent of a
/// reference lift, held against a published table. A lift well under its ratio is the one
/// holding the others back. The tables live in `StructuralBalanceTemplates.swift`.
enum StructuralBalance {
    enum Status: Equatable {
        case balanced, borderline, weak, noData
    }

    struct Lift: Equatable, Identifiable {
        let id: String
        let name: String
        /// Library exercises whose sets count; the best reading among them wins.
        let exercises: [String]
        /// Percent of the group's reference lift.
        let targetPct: Double
        /// A dip or a chin-up moves the lifter too, and the sources count body weight plus load.
        var includesBodyweight = false
    }

    struct Group: Equatable, Identifiable {
        let id: String
        let title: String
        let reference: Lift
        let lifts: [Lift]
    }

    struct Template: Equatable, Identifiable {
        let id: String
        let title: String
        let citation: String
        let url: URL?
        /// What was left out of the source table, and why.
        let note: String
        let groups: [Group]
    }

    struct Row: Equatable, Identifiable {
        let lift: Lift
        /// Best estimated one-rep max in kg moved, body weight included where the lift counts it.
        let oneRepMaxKg: Double?
        /// The library exercise that reading came from.
        let exercise: String?
        let actualPct: Double?
        let status: Status
        /// Sets are logged, but they can't be scored until a body weight is known.
        let needsBodyweight: Bool

        var id: String { lift.id }
    }

    /// Percentage points under the target that still read as borderline rather than weak.
    static let borderlineBand = 5.0

    static func classify(actualPct: Double?, targetPct: Double) -> Status {
        guard let actualPct, actualPct.isFinite else { return .noData }
        // Loads exactly at a ratio can land a float hair under it once divided.
        let slack = 1e-9
        if actualPct >= targetPct - slack { return .balanced }
        return actualPct >= targetPct - borderlineBand - slack ? .borderline : .weak
    }

    /// What one set moved. nil when it can't be known (no body weight) or wasn't a lift at all.
    static func movedKg(_ set: SetValue, exercise: String, includesBodyweight: Bool, bodyweightKg: Double?) -> Double? {
        let assisted = ExerciseProgress.isAssisted(name: exercise)
        guard includesBodyweight || assisted else { return set.weightKg > 0 ? set.weightKg : nil }
        guard let bodyweightKg, bodyweightKg > 0 else { return nil }
        guard assisted else { return bodyweightKg + set.weightKg }
        // 0 is a set with no help typed in, and help at or above body weight moved nothing.
        let moved = bodyweightKg - set.weightKg
        return set.weightKg > 0 && moved > 0 ? moved : nil
    }

    private static func best(_ lift: Lift, history: [String: [SetValue]], bodyweightKg: Double?) -> (kg: Double, exercise: String)? {
        var best: (kg: Double, exercise: String)?
        for exercise in lift.exercises {
            for set in history[exercise] ?? [] where set.kind.countsTowardProgress && set.durationSeconds == nil {
                guard let moved = movedKg(set, exercise: exercise, includesBodyweight: lift.includesBodyweight, bodyweightKg: bodyweightKg)
                else { continue }
                let estimate = OneRepMax.epley(weightKg: moved, reps: set.reps)
                if estimate > (best?.kg ?? 0) { best = (estimate, exercise) }
            }
        }
        return best
    }

    private static func waitsOnBodyweight(_ lift: Lift, history: [String: [SetValue]], bodyweightKg: Double?) -> Bool {
        guard (bodyweightKg ?? 0) <= 0 else { return false }
        return lift.exercises.contains { exercise in
            (lift.includesBodyweight || ExerciseProgress.isAssisted(name: exercise))
                && (history[exercise] ?? []).contains { $0.kind.countsTowardProgress && $0.reps > 0 }
        }
    }

    /// `history` is every completed set per exercise name.
    static func evaluate(_ group: Group, history: [String: [SetValue]], bodyweightKg: Double?) -> (reference: Row, rows: [Row]) {
        let anchor = best(group.reference, history: history, bodyweightKg: bodyweightKg)

        func row(_ lift: Lift, isReference: Bool) -> Row {
            let reading = isReference ? anchor : best(lift, history: history, bodyweightKg: bodyweightKg)
            let actual: Double? = reading.flatMap { reading in anchor.map { reading.kg / $0.kg * 100 } }
            return Row(
                lift: lift, oneRepMaxKg: reading?.kg, exercise: reading?.exercise, actualPct: actual,
                status: classify(actualPct: actual, targetPct: lift.targetPct),
                needsBodyweight: reading == nil && waitsOnBodyweight(lift, history: history, bodyweightKg: bodyweightKg)
            )
        }
        return (row(group.reference, isReference: true), group.lifts.map { row($0, isReference: false) })
    }
}
