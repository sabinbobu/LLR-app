import SwiftData
import SwiftUI

struct RunDetailView: View {
    let workout: Workout
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 40) {
                RunStat(label: "Time", value: Format.duration(workout.duration))
                RunStat(label: "Started", value: workout.startedAt.formatted(date: .omitted, time: .shortened))
                RunStat(label: "Day", value: workout.startedAt.formatted(.dateTime.weekday(.wide)))
            }
            Text(workout.startedAt.formatted(date: .complete, time: .omitted)).foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background)
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Delete", systemImage: "trash", role: .destructive) { confirmDelete = true }
        }
        .confirmationDialog("Delete this run?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Run", role: .destructive) {
                dismiss()
                WorkoutActions.delete(workout, in: context)
            }
        } message: {
            Text("This can't be undone.")
        }
    }
}
