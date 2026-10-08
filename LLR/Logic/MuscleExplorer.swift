import CoreGraphics
import Foundation

/// What the explorer reads off an exercise; a protocol so the matching is testable without SwiftData.
protocol MuscleTargeting {
    var muscleGroup: String { get }
    var secondaryMuscles: [String] { get }
    var equipment: [String] { get }
    var isFavourite: Bool { get }
}

extension Exercise: MuscleTargeting {}

/// Browsing the library from the body map: which exercises train a tapped muscle.
enum MuscleExplorer {
    struct Hit<T> {
        let item: T
        /// False when the muscle only assists, so the list can say so instead of overselling it.
        let isPrimary: Bool
    }

    /// The muscles offered as chips: everything the body map can draw.
    static let muscles: [MuscleGroup] = MuscleGroup.allCases.filter(\.isTrainable)

    /// How many exercises train each muscle, as the main target or an assisting one.
    static func counts<T: MuscleTargeting>(_ items: [T]) -> [MuscleGroup: Int] {
        var result: [MuscleGroup: Int] = [:]
        for item in items {
            let targets = Set(([item.muscleGroup] + item.secondaryMuscles).compactMap(MuscleGroup.init(rawValue:)))
            for muscle in targets where muscle.isTrainable {
                result[muscle, default: 0] += 1
            }
        }
        return result
    }

    /// Main targets first, then exercises where the muscle only assists. Favourites lead each half;
    /// otherwise the incoming order is kept.
    static func hits<T: MuscleTargeting>(for muscle: MuscleGroup, in items: [T], equipment: String? = nil) -> [Hit<T>] {
        let pool = equipment.map { filter in items.filter { Equipment.matches($0.equipment, filter: filter) } } ?? items
        let primary = pool.filter { $0.muscleGroup == muscle.rawValue }
        let secondary = pool.filter { $0.muscleGroup != muscle.rawValue && $0.secondaryMuscles.contains(muscle.rawValue) }
        return ExerciseFavourites.favouritesFirst(primary, isFavourite: \.isFavourite).map { Hit(item: $0, isPrimary: true) }
            + ExerciseFavourites.favouritesFirst(secondary, isFavourite: \.isFavourite).map { Hit(item: $0, isPrimary: false) }
    }

    /// The muscles drawn under a point in a side's 0–1 box; empty for bare space, head or knees.
    static func groups(at point: CGPoint, side: BodyMapSide) -> [MuscleGroup] {
        BodyMapHitTest.region(at: point, in: side.regions).map(BodyMapData.muscleGroups) ?? []
    }

    /// What a tap selects. One drawn region can cover two tracked muscles (upper back and lats), so
    /// repeat taps step through them and then clear, which also makes a second tap the way to deselect.
    static func selection(tapping groups: [MuscleGroup], current: MuscleGroup?) -> MuscleGroup? {
        guard !groups.isEmpty else { return current }
        guard let current, let index = groups.firstIndex(of: current) else { return groups.first }
        return index + 1 < groups.count ? groups[index + 1] : nil
    }
}
