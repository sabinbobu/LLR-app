import Foundation

/// A stand-in for a lift is almost always another lift for the same muscle, so the swap picker opens there.
enum SwapFilter {
    /// Groups that describe how an exercise trains rather than a muscle would filter to an unhelpful list.
    private static let tooBroad: Set<String> = [MuscleGroup.fullBody.rawValue, MuscleGroup.other.rawValue, MuscleGroup.cardio.rawValue]

    static func muscle(for exercise: Exercise?) -> String? {
        guard let group = exercise?.muscleGroup, !group.isEmpty, !tooBroad.contains(group) else { return nil }
        return group
    }
}
