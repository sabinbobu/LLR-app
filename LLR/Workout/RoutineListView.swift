import SwiftData
import SwiftUI

struct RoutineListView: View {
    @Query(filter: #Predicate<Routine> { $0.sectionRaw == "gym" }, sort: \Routine.createdAt, order: .reverse)
    private var routines: [Routine]
    @Environment(\.modelContext) private var context
    let onStart: (Routine) -> Void
    @State private var editing: Routine?

    var body: some View {
        List {
            if routines.isEmpty {
                EmptyStateCard(systemImage: "clipboard", message: "No routines yet")
                    .listRowSeparator(.hidden)
            }
            ForEach(routines) { routine in
                Button { editing = routine } label: {
                    row(routine)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) { context.delete(routine) }
                }
            }
        }
        .navigationTitle("My Routines")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { RoutineBuilderView(routine: $0) }
    }

    private func row(_ routine: Routine) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name.isEmpty ? "Untitled Routine" : routine.name).font(.headline)
                Text(routine.orderedExercises.compactMap { $0.exercise?.name }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Button("Start") { onStart(routine) }
                .buttonStyle(.borderedProminent)
                .disabled(routine.orderedExercises.isEmpty)
        }
        .foregroundStyle(.primary)
    }
}
