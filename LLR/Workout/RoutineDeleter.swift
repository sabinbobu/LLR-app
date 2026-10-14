import Observation
import SwiftData
import SwiftUI

/// Deletes a routine at once and keeps a snapshot for the Undo bar. Shared by the Workout tab and
/// the See All list so both behave the same.
@MainActor
@Observable
final class RoutineDeleter {
    struct Pending: Identifiable {
        let id = UUID()
        let snapshot: RoutineSnapshot
    }

    private(set) var pending: Pending?
    private var dismissTask: Task<Void, Never>?

    func delete(_ routine: Routine, in context: ModelContext) {
        let entry = Pending(snapshot: RoutineSnapshot(routine))
        context.delete(routine)
        pending = entry
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            withAnimation { self?.pending = nil }
        }
    }

    func undo(in context: ModelContext) {
        guard let entry = pending else { return }
        dismissTask?.cancel()
        entry.snapshot.restore(in: context)
        withAnimation { pending = nil }
    }
}

private struct RoutineUndoToast: ViewModifier {
    let deleter: RoutineDeleter
    @Environment(\.modelContext) private var context

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            if deleter.pending != nil {
                UndoToast(title: "Routine deleted") { deleter.undo(in: context) }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func routineUndoToast(_ deleter: RoutineDeleter) -> some View {
        modifier(RoutineUndoToast(deleter: deleter))
    }
}
