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

/// The two menu entries, so the long-press menu and a card's ⋯ button can't drift apart.
private struct WorkoutActionItems: View {
    let workout: Workout
    let canStart: Bool
    let onRepeat: () -> Void
    @Binding var confirmDelete: Bool

    var body: some View {
        // Gym only: a Kineto session starts through its own pain check-in.
        if workout.section == .gym && !workout.isRun {
            Button(WorkoutActions.repeatLabel(canStart: canStart), systemImage: "arrow.clockwise", action: onRepeat)
                .disabled(!canStart)
        }
        Button("Delete Workout", systemImage: "trash", role: .destructive) { confirmDelete = true }
    }
}

private struct DeleteWorkoutDialog: ViewModifier {
    let workout: Workout
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context

    func body(content: Content) -> some View {
        content.confirmationDialog("Delete this workout?", isPresented: $isPresented, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) { WorkoutActions.delete(workout, in: context) }
        } message: {
            Text(WorkoutActions.deleteMessage(for: workout))
        }
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
                WorkoutActionItems(workout: workout, canStart: unfinished.isEmpty, onRepeat: {
                    presenter.present(WorkoutFactory.start(copying: workout, in: context))
                }, confirmDelete: $confirmDelete)
            }
            .modifier(DeleteWorkoutDialog(workout: workout, isPresented: $confirmDelete))
    }
}

extension View {
    func workoutActions(_ workout: Workout) -> some View {
        modifier(WorkoutActionsModifier(workout: workout))
    }
}

/// The ⋯ button on a history card: the same Repeat/Delete as the long-press menu, for people who
/// don't know to long-press.
struct WorkoutMoreMenu: View {
    let workout: Workout
    @Environment(\.modelContext) private var context
    @Environment(ActiveWorkoutPresenter.self) private var presenter
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]
    @State private var confirmDelete = false

    var body: some View {
        Menu {
            WorkoutActionItems(workout: workout, canStart: unfinished.isEmpty, onRepeat: {
                presenter.present(WorkoutFactory.start(copying: workout, in: context))
            }, confirmDelete: $confirmDelete)
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More options")
        .modifier(DeleteWorkoutDialog(workout: workout, isPresented: $confirmDelete))
    }
}
