import Foundation

enum PersonalRecords {
    enum Kind: String, CaseIterable, Comparable {
        case weight, oneRepMax, setVolume

        var title: String {
            switch self {
            case .weight: "Heaviest Weight"
            case .oneRepMax: "Best 1RM"
            case .setVolume: "Best Set Volume"
            }
        }

        static func < (lhs: Kind, rhs: Kind) -> Bool {
            allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
        }
    }

    static func metric(_ kind: Kind, _ set: SetValue) -> Double {
        switch kind {
        case .weight: set.weightKg
        case .oneRepMax: OneRepMax.epley(set)
        case .setVolume: set.weightKg * Double(set.reps)
        }
    }

    /// `earlierToday` raises the bar within a session so only the set that actually moved the record
    /// is flagged, not every set after it. No history means no baseline — a first session isn't a PR.
    static func kinds(for set: SetValue, history: [SetValue], earlierToday: [SetValue]) -> Set<Kind> {
        let past = history.filter(\.kind.countsTowardProgress)
        guard set.kind.countsTowardProgress, set.weightKg > 0, set.reps > 0, !past.isEmpty else { return [] }
        let prior = past + earlierToday.filter(\.kind.countsTowardProgress)
        return Set(Kind.allCases.filter { kind in
            let best = prior.map { metric(kind, $0) }.max() ?? 0
            // Tolerance so float noise on an equal lift never registers as a record.
            return metric(kind, set) > best + 1e-6
        })
    }
}
