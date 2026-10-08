import Foundation

extension WorkoutExercise {
    var supersetMember: Superset.Member {
        Superset.Member(group: supersetGroup, completed: orderedSets.map { $0.completedAt != nil })
    }
}

extension ActiveWorkoutModel {
    func pairWithNext(_ entry: WorkoutExercise) { regroup(entry, Superset.pairing) }
    func unpair(_ entry: WorkoutExercise) { regroup(entry, Superset.unpairing) }

    private func regroup(_ entry: WorkoutExercise, _ change: ([Int?], Int) -> [Int?]) {
        let entries = workout.orderedExercises
        guard let index = entries.firstIndex(where: { $0 === entry }) else { return }
        for (entry, group) in zip(entries, change(entries.map(\.supersetGroup), index)) where entry.supersetGroup != group {
            entry.supersetGroup = group
        }
        syncLockScreen()
    }

    func supersetTag(for entry: WorkoutExercise) -> Superset.Tag? {
        let entries = workout.orderedExercises
        guard let index = entries.firstIndex(where: { $0 === entry }) else { return nil }
        return Superset.tags(entries.map(\.supersetGroup))[index]
    }

    /// There is an exercise after this one that it isn't already grouped with.
    func canPairWithNext(_ entry: WorkoutExercise) -> Bool {
        let entries = workout.orderedExercises
        guard let index = entries.firstIndex(where: { $0 === entry }), index + 1 < entries.count else { return false }
        return entry.supersetGroup == nil || entries[index + 1].supersetGroup != entry.supersetGroup
    }

    func endsRound(_ set: SetEntry) -> Bool {
        let entries = workout.orderedExercises
        guard let entry = set.workoutExercise,
              let exercise = entries.firstIndex(where: { $0 === entry }),
              let index = entry.orderedSets.firstIndex(where: { $0 === set })
        else { return true }
        return Superset.endsRound(entries.map(\.supersetMember), exercise: exercise, set: index)
    }
}
