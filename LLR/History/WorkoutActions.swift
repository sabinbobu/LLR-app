import SwiftData
import SwiftUI

/// Repeat and delete for a recorded workout, shared by the history lists and the detail screen.
@MainActor
enum WorkoutActions {
    /// The widget streak is derived from finished workouts, so it is refreshed in the same action
    /// instead of waiting for the next time the app backgrounds.
    static func delete(_ workout: Workout, in context: ModelContext) {
        context.delete(workout)
        try? context.save()
        TrainingSnapshotSync.sync(context: context)
    }

    static func deleteMessage(for workout: Workout) -> String {
        workout.hasPainRecorded
            ? "This also deletes the pain log recorded with this session. This can't be undone."
            : "This can't be undone."
    }

    static func repeatLabel(canStart: Bool) -> String {
        canStart ? "Repeat Workout" : "Repeat Workout (finish current first)"
    }
}

private struct WorkoutActionsModifier: ViewModifier {
    let workout: Workout
    @Environment(\.modelContext) private var context
    @Environment(ActiveWorkoutPresenter.self) private var presenter
    // Section-agnostic: only one workout can be in progress at a time.
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]
    @State private var confirmDelete = false

    func body(content: Content) -> some View {
        content
            .contextMenu {
                // Gym only: a Kineto session starts through its own pain check-in.
                if workout.section == .gym && !workout.isRun {
                    Button(WorkoutActions.repeatLabel(canStart: unfinished.isEmpty), systemImage: "arrow.clockwise") {
                        presenter.present(WorkoutFactory.start(copying: workout, in: context))
                    }
                    .disabled(!unfinished.isEmpty)
                }
                Button("Delete Workout", systemImage: "trash", role: .destructive) { confirmDelete = true }
            }
            .confirmationDialog("Delete this workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete Workout", role: .destructive) { WorkoutActions.delete(workout, in: context) }
            } message: {
                Text(WorkoutActions.deleteMessage(for: workout))
            }
    }
}

extension View {
    func workoutActions(_ workout: Workout) -> some View {
        modifier(WorkoutActionsModifier(workout: workout))
    }
}
