import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @AppStorage(StorageKey.effortScale) private var effortScale: EffortScale = .off
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var editing = false
    @State private var showingShare = false
    // Section-agnostic, as on the Workout tab: only one workout can be in progress at a time.
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]
    @State private var repeating: Workout?
    @State private var savedRoutine: Routine?
    /// Set once the active-workout cover dismisses so the summary sheet doesn't fight it for presentation.
    @State private var justFinished: Workout?
    @State private var pendingSummary: Workout?

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
            // No estimate for a bodyweight set or one past the rep cap, so nothing to print for it.
            let estimate = OneRepMax.estimate(row.set.value)
            let oneRepMax = estimate > 0 ? "1RM \(unit.format(kg: estimate))" : nil
            if let rir = row.set.rir, effortScale != .off {
                trailing = ["\(effortScale.title) \(Effort.text(rir: rir, scale: effortScale))", oneRepMax].compactMap { $0 }.joined(separator: " · ")
            } else {
                trailing = oneRepMax
            }
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
            // Gym only: a back-care session is not a lift to beat.
            if workout.section == .gym {
                WorkoutInsightsCard(workout: workout)
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
            ShareLink(item: workout.plainText(unit: unit)) {
                Image(systemName: "doc.on.doc")
            }
            .accessibilityLabel("Share workout as text")
            Button("Edit") { editing = true }
            Menu {
                // Gym only: a Kineto session starts through its own pain check-in.
                if workout.section == .gym {
                    Button("Repeat Workout", systemImage: "arrow.clockwise") {
                        repeating = WorkoutFactory.start(copying: workout, in: context)
                    }
                    .disabled(!unfinished.isEmpty)
                    Button("Save as Routine", systemImage: "list.clipboard") {
                        savedRoutine = RoutineFactory.save(workout, in: context)
                    }
                }
                Button("Delete Workout", systemImage: "trash", role: .destructive) { confirmDelete = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More")
        }
        .fullScreenCover(isPresented: $editing) { WorkoutEditorView(workout: workout) }
        .fullScreenCover(item: $repeating, onDismiss: {
            justFinished = pendingSummary
            pendingSummary = nil
        }) { started in
            ActiveWorkoutView(workout: started) { pendingSummary = $0 }
        }
        .sheet(item: $justFinished) { WorkoutSummaryView(workout: $0) }
        // Opens the new routine straight away, so it can be renamed or trimmed while it's in mind.
        .sheet(item: $savedRoutine) { RoutineBuilderView(routine: $0) }
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
