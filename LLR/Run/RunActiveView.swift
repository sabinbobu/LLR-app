import SwiftData
import SwiftUI

/// A stopwatch for a run in progress. Closing it with the chevron keeps the run going (the mini bar
/// brings it back); only Finish or Discard ends it.
struct RunActiveView: View {
    let workout: Workout
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDiscard = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "figure.run").font(.system(size: 44)).foregroundStyle(Theme.accent)
                Text(workout.startedAt, style: .timer)
                    .font(.system(size: 72, weight: .semibold).monospacedDigit())
                    .minimumScaleFactor(0.5)
                Text("Started \(workout.startedAt.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Finish Run") {
                    WorkoutFactory.finishRun(workout, in: context)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Discard Run", role: .destructive) { confirmDiscard = true }
            }
            .padding()
            .background(Theme.background)
            .navigationTitle("Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "chevron.down") }
                        .accessibilityLabel("Minimise")
                }
            }
            .confirmationDialog("Discard this run?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard Run", role: .destructive) {
                    dismiss()
                    context.delete(workout)
                    try? context.save()
                }
            }
        }
    }
}
