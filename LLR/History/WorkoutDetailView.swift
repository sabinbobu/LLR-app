import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var editing = false
    @State private var showingShare = false

    // Precomputed rows keep `body` cheap to type-check; the inline version took 11s per build.
    private struct Row: Identifiable {
        let id: PersistentIdentifier
        let label: String
        let set: SetEntry
        let records: Set<PersonalRecords.Kind>
    }

    private func rows(for entry: WorkoutExercise) -> [Row] {
        let ordered: [SetEntry] = entry.orderedSets
        let records: [Set<PersonalRecords.Kind>] = entry.recordKinds()
        let completed: [(SetEntry, Set<PersonalRecords.Kind>)] = zip(ordered, records).filter { $0.0.completedAt != nil }
        let labels: [String] = SetKind.labels(for: completed.map { $0.0.kind })
        return completed.enumerated().map { index, pair in
            Row(id: pair.0.persistentModelID, label: labels[index], set: pair.0, records: pair.1)
        }
    }

    private func setRow(_ row: Row) -> some View {
        let labelColor: Color = row.set.kind == .normal ? .secondary : SetRowView.color(for: row.set.kind)
        // Duration sets have no weight, so there's no 1RM to show either.
        let detail: String
        let trailing: String?
        if let seconds = row.set.durationSeconds {
            detail = "\(row.set.reps) × \(seconds) s"
            trailing = nil
        } else {
            detail = "\(unit.format(kg: row.set.weightKg)) \(unit.rawValue) × \(row.set.reps)"
            trailing = "1RM \(unit.format(kg: OneRepMax.epley(row.set.value)))"
        }
        return HStack {
            Text(row.label)
                .foregroundStyle(labelColor)
                .frame(width: 28, alignment: .leading)
            Text(detail)
            if !row.records.isEmpty {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel(row.records.sorted().map(\.title).joined(separator: ", "))
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .monospacedDigit()
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Started", value: workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Duration", value: Format.duration(workout.duration))
                LabeledContent("Volume", value: "\(unit.format(kg: workout.volumeKg)) \(unit.rawValue)")
            }
            if !workout.notes.isEmpty {
                Section("Notes") {
                    Text(workout.notes)
                }
            }
            ForEach(workout.orderedExercises) { entry in
                Section(entry.exercise?.name ?? "Exercise") {
                    ForEach(rows(for: entry)) { row in
                        setRow(row)
                    }
                }
            }
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Gym only: Kineto shares its own separate CSV log, not this card.
            if workout.section == .gym {
                Button {
                    showingShare = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            Button("Edit") { editing = true }
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Image(systemName: "trash")
            }
        }
        .fullScreenCover(isPresented: $editing) { WorkoutEditorView(workout: workout) }
        .sheet(isPresented: $showingShare) {
            WorkoutShareCard(workout: workout, recap: WorkoutRecap(workout), unit: unit)
                .presentationDetents([.medium])
        }
        .confirmationDialog("Delete this workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) {
                dismiss()
                context.delete(workout)
            }
        }
    }
}
