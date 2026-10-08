import Foundation

extension ExerciseProgress {
    /// What the progress chart plots, one value per session.
    enum Metric: String, CaseIterable, Identifiable {
        case oneRepMax, topSet, maxReps, effort

        var id: String { rawValue }

        func title(assisted: Bool) -> String {
            switch self {
            case .oneRepMax: "One Rep Max"
            case .topSet: assisted ? "Least Help" : "Heaviest Weight"
            case .maxReps: "Most Reps"
            case .effort: "Effort"
            }
        }
    }

    /// On an assisted machine the stack lifts part of the lifter, so the number logged is help:
    /// progress is that number going down. Read from the name because that is how the library
    /// marks them ("Pull Up (Assisted)"), and a custom exercise named the same way means the same.
    static func isAssisted(name: String) -> Bool {
        name.localizedCaseInsensitiveContains("assisted")
    }

    /// An estimated max of the help given means nothing, and an effort chart with no rated set
    /// would be an empty tab.
    static func metrics(assisted: Bool, rated: Bool) -> [Metric] {
        Metric.allCases.filter { metric in
            switch metric {
            case .oneRepMax: !assisted
            case .effort: rated
            case .topSet, .maxReps: true
            }
        }
    }

    static func series(
        _ sessions: [Session], metric: Metric, assisted: Bool = false, formula: OneRepMax.Formula = .stored
    ) -> [Point] {
        if metric == .oneRepMax { return oneRepMaxSeries(sessions, formula: formula) }
        return points(sessions) { sets in
            switch metric {
            case .oneRepMax: return nil
            // 0 on an assisted machine is a set with no load typed in, not an unassisted rep.
            case .topSet where assisted: return sets.map(\.weightKg).filter { $0 > 0 }.min()
            case .topSet: return sets.map(\.weightKg).max()
            case .maxReps: return sets.map { Double($0.reps) }.max()
            case .effort:
                let ratings = sets.compactMap(\.rir)
                return ratings.isEmpty ? nil : ratings.reduce(0, +) / Double(ratings.count)
            }
        }
    }

    static func bestSet(in sessions: [Session], assisted: Bool, formula: OneRepMax.Formula = .stored) -> SetValue? {
        guard assisted else { return bestSet(in: sessions, formula: formula) }
        return working(sessions).flatMap(\.sets)
            .filter { $0.weightKg > 0 && $0.reps > 0 }
            .min { a, b in a.weightKg == b.weightKg ? a.reps > b.reps : a.weightKg < b.weightKg }
    }

    /// Newest first, for the list under the chart.
    static func recent(_ sessions: [Session], limit: Int = 5) -> [Session] {
        Array(working(sessions).sorted { $0.date > $1.date }.prefix(limit))
    }

    static func setsText(_ sets: [SetValue], unit: WeightUnit) -> String {
        sets.map { set in
            if let seconds = set.durationSeconds { return "\(set.reps) × \(seconds) s" }
            if set.weightKg == 0 { return "\(set.reps) reps" }
            return "\(unit.format(kg: set.weightKg)) × \(set.reps)"
        }
        .joined(separator: ", ")
    }
}
