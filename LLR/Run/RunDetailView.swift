import SwiftData
import SwiftUI

struct RunDetailView: View {
    let workout: Workout
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 32) {
                    if let km = workout.distanceKm {
                        RunStat(label: "Distance", value: "\(km.formatted(.number.precision(.fractionLength(0...2)))) km")
                    }
                    RunStat(label: "Time", value: Format.duration(workout.duration))
                    RunStat(label: "Started", value: workout.startedAt.formatted(date: .omitted, time: .shortened))
                }
                Text(workout.startedAt.formatted(date: .complete, time: .omitted)).foregroundStyle(.secondary)
                if let km = workout.distanceKm, workout.duration > 0 {
                    RunEffectView(km: km, seconds: workout.duration)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
