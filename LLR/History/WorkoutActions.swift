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

/// Repeat and Delete as menu items, shared by the long-press menu and the card's ⋯ button.
struct WorkoutActionButtons: View {
    let workout: Workout
    @Binding var confirmDelete: Bool
    @Environment(\.modelContext) private var context
    @Environment(ActiveWorkoutPresenter.self) private var presenter
    // Section-agnostic: only one workout can be in progress at a time.
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]

    var body: some View {
        // Gym only: a Kineto session starts through its own pain check-in.
        if workout.section == .gym && !workout.isRun {
            Button(WorkoutActions.repeatLabel(canStart: unfinished.isEmpty), systemImage: "arrow.clockwise") {
                presenter.present(WorkoutFactory.start(copying: workout, in: context))
            }
            .disabled(!unfinished.isEmpty)
        }
        Button("Delete Workout", systemImage: "trash", role: .destructive) { confirmDelete = true }
    }
}

private extension View {
    func confirmingDelete(of workout: Workout, isPresented: Binding<Bool>, in context: ModelContext) -> some View {
        confirmationDialog("Delete this workout?", isPresented: isPresented, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) { WorkoutActions.delete(workout, in: context) }
        } message: {
            Text(WorkoutActions.deleteMessage(for: workout))
        }
    }
}

private struct WorkoutActionsModifier: ViewModifier {
    let workout: Workout
    @Environment(\.modelContext) private var context
    @State private var confirmDelete = false

    func body(content: Content) -> some View {
        content
            .contextMenu { WorkoutActionButtons(workout: workout, confirmDelete: $confirmDelete) }
            .confirmingDelete(of: workout, isPresented: $confirmDelete, in: context)
    }
}

/// The ⋯ button on a history card. Same actions as long-press, for people who do not find that.
struct WorkoutMenuButton: View {
    let workout: Workout
    @Environment(\.modelContext) private var context
    @State private var confirmDelete = false

    var body: some View {
        Menu {
            WorkoutActionButtons(workout: workout, confirmDelete: $confirmDelete)
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More options")
        .confirmingDelete(of: workout, isPresented: $confirmDelete, in: context)
    }
}

extension View {
    func workoutActions(_ workout: Workout) -> some View {
        modifier(WorkoutActionsModifier(workout: workout))
    }
}
