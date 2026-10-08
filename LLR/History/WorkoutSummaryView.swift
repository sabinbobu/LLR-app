import SwiftUI

/// Shown once, right after Finish — a snapshot of what just happened, not a place to keep editing.
struct WorkoutSummaryView: View {
    let workout: Workout
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @Environment(\.dismiss) private var dismiss
    @State private var showingShare = false

    private var recap: WorkoutRecap { WorkoutRecap(workout) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(workout.title).font(.title2.weight(.semibold))
                    statsRow
                    BodyMapView { groups in Self.tint(groups, recap: recap) }
                        .frame(height: 220)
                    if !recap.records.isEmpty {
                        recordsCard
                    }
                    WorkoutInsightsCard(workout: workout, boxed: true)
                }
                .padding()
            }
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShare) {
                WorkoutShareCard(workout: workout, recap: recap, unit: unit)
                    .presentationDetents([.medium])
            }
            .safeAreaInset(edge: .bottom) {
                Button("Done") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
            }
        }
        .interactiveDismissDisabled()
    }

    /// Shared with `WorkoutShareCard` so the on-screen summary and the shared image agree.
    static func tint(_ groups: [MuscleGroup], recap: WorkoutRecap) -> Color? {
        if groups.contains(where: recap.primaryMuscles.contains) { return Theme.accent }
        if groups.contains(where: recap.secondaryMuscles.contains) { return Theme.accent.opacity(0.4) }
        return nil
    }

    private var statsRow: some View {
        HStack(spacing: 32) {
            statCell("Weight", "\(unit.format(kg: recap.volumeKg)) \(unit.rawValue)")
            statCell("Duration", Format.duration(recap.duration))
            statCell("Sets", "\(recap.setCount)")
        }
        .monospacedDigit()
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.semibold))
        }
    }

    private var recordsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("New Records").font(.headline)
            ForEach(recap.records) { line in
                HStack {
                    Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                    Text("\(line.exerciseName) — \(line.kind.title) \(unit.format(kg: line.valueKg)) \(unit.rawValue)")
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
