import ActivityKit
import Foundation
import SwiftData

/// Keeps the Lock Screen Live Activity in step with the unfinished workout in the store. It reads
/// the store rather than any screen's state because its buttons can fire while the app is suspended
/// or relaunched in the background, when no workout screen exists.
@MainActor
enum LiveWorkoutActivity {
    private static var context: ModelContext { Persistence.container.mainContext }

    static func currentWorkout() -> Workout? {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    static func nextSet(in workout: Workout) -> SetEntry? {
        let entries = loggable(workout)
        guard let position = LiveWorkoutContent.next(in: entries.map(content)) else { return nil }
        return entries[position.exercise].orderedSets[position.set]
    }

    /// Call after anything that changes what the Lock Screen should show; it updates or ends the
    /// activity to match. Only opening the workout screen may start one: a workout abandoned
    /// yesterday shouldn't reappear on the Lock Screen just because the app launched.
    static func sync(startIfNeeded: Bool = false) {
        guard let workout = currentWorkout() else {
            end(Activity<WorkoutActivityAttributes>.activities)
            return
        }
        let timer = RestTimer.shared
        let state = LiveWorkoutContent.state(
            loggable(workout).map(content), unit: .stored,
            restStartedAt: timer.startDate, restEndsAt: timer.endDate
        )
        // Stale once the rest runs out, so the Lock Screen drops the countdown even if the app is asleep.
        let activityContent = ActivityContent(state: state, staleDate: timer.endDate)
        let activities = Activity<WorkoutActivityAttributes>.activities
        if let current = activities.first(where: { $0.attributes.startedAt == workout.startedAt }) {
            end(activities.filter { $0.id != current.id })
            Task { await current.update(activityContent) }
        } else {
            end(activities)
            guard startIfNeeded, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            let attributes = WorkoutActivityAttributes(workoutName: workout.title, startedAt: workout.startedAt)
            _ = try? Activity.request(attributes: attributes, content: activityContent)
        }
    }

    static func restoreRest() {
        guard let state = Activity<WorkoutActivityAttributes>.activities.first?.content.state,
              let start = state.restStartedAt, let end = state.restEndsAt
        else { return }
        RestTimer.shared.restore(start: start, end: end)
    }

    private static func end(_ activities: [Activity<WorkoutActivityAttributes>]) {
        for activity in activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    private static func loggable(_ workout: Workout) -> [WorkoutExercise] {
        workout.orderedExercises.filter { $0.exercise != nil }
    }

    private static func content(_ entry: WorkoutExercise) -> LiveWorkoutContent.Exercise {
        let sets = entry.orderedSets
        return .init(
            name: entry.exercise?.name ?? "", sets: sets.map(\.value),
            completed: sets.map { $0.completedAt != nil }, supersetGroup: entry.supersetGroup
        )
    }
}

/// What the Lock Screen buttons do, through the same model code as the workout screen.
@MainActor
enum LiveWorkoutActions {
    static func completeNextSet() {
        guard let workout = LiveWorkoutActivity.currentWorkout(),
              let set = LiveWorkoutActivity.nextSet(in: workout)
        else { return }
        ActiveWorkoutModel(workout: workout).toggle(set)
        // The app may be suspended again right after this returns; autosave won't get the chance.
        try? workout.modelContext?.save()
        LiveWorkoutActivity.sync()
    }

    static func adjustRest(by seconds: Int) {
        LiveWorkoutActivity.restoreRest()
        RestTimer.shared.adjust(by: seconds)
    }

    static func skipRest() {
        LiveWorkoutActivity.restoreRest()
        RestTimer.shared.skip()
    }
}
