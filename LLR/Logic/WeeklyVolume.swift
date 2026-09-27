import Foundation

/// Hard sets per muscle for one calendar week, read against evidence-based zones.
///
/// - The ~10 sets/week line comes from Schoenfeld, Ogborn & Krieger 2017 (J Sports Sci 35(11):1073–82),
///   where ≥10 weekly sets per muscle outgrew <5.
/// - Counting a secondary muscle as half a set follows Pelland et al. 2025 (Sports Med,
///   doi:10.1007/s40279-025-02344-w), where this "fractional" method predicted hypertrophy best.
///
/// The 20-set upper edge is a practical ceiling, not a finding: the returns keep diminishing, and past
/// it recovery, not stimulus, is usually the limit.
enum WeeklyVolume {
    enum Band: Equatable {
        case none, low, building, target, high
    }

    static let targetRange: ClosedRange<Double> = 10...20

    static func band(for sets: Double) -> Band {
        switch sets {
        case ..<0.001: .none
        case ..<5: .low
        case ..<targetRange.lowerBound: .building
        case targetRange: .target
        default: .high
        }
    }

    static func sets(
        _ entries: [MuscleRecovery.Entry],
        week: Date,
        calendar: Calendar = .current
    ) -> [MuscleGroup.RadarAxis: Double] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: week) else { return [:] }
        var totals: [MuscleGroup.RadarAxis: Double] = [:]
        for entry in entries where interval.start <= entry.completedAt && entry.completedAt < interval.end {
            // Several muscles fold into one axis (lats + upper back → Back), so one set can reach the
            // same axis twice. It is still one set: keep the larger credit instead of summing.
            var credit: [MuscleGroup.RadarAxis: Double] = [:]
            func apply(_ rawMuscle: String, _ value: Double) {
                guard let axis = MuscleGroup(rawValue: rawMuscle)?.radarAxis else { return }
                credit[axis] = max(credit[axis] ?? 0, value)
            }
            apply(entry.muscle, 1)
            for secondary in entry.secondaryMuscles { apply(secondary, 0.5) }
            totals.merge(credit, uniquingKeysWith: +)
        }
        return totals
    }
}
