import SwiftUI

struct ExerciseLogCard: View {
    let entry: WorkoutExercise
    let model: ActiveWorkoutModel
    let unit: WeightUnit
    @AppStorage(StorageKey.effortScale) private var effortScale: EffortScale = .off
    @State private var plateTargetKg: Double?
    @State private var showingDetails = false
    @State private var editingNote = false
    @State private var swapping = false

    private var showingPlates: Binding<Bool> {
        Binding(get: { plateTargetKg != nil }, set: { if !$0 { plateTargetKg = nil } })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Image(systemName: "dumbbell.fill")
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Theme.border))
                Text(entry.exercise?.name ?? "Exercise")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Theme.accent)
                Spacer()
                Menu {
                    if let exercise = entry.exercise {
                        Button("Exercise Details", systemImage: "info.circle") { showingDetails = true }
                        Button(exercise.personalNotes.isEmpty ? "Add Note" : "Edit Note", systemImage: "note.text") { editingNote = true }
                    }
                    // Kineto picks come with a dose level, so a plain swap doesn't fit there.
                    if model.workout.section == .gym {
                        Button("Swap Exercise", systemImage: "arrow.triangle.2.circlepath") { swapping = true }
                    }
                    if model.canMove(entry, by: -1) {
                        Button("Move Up", systemImage: "arrow.up") { model.move(entry, by: -1) }
                    }
                    if model.canMove(entry, by: 1) {
                        Button("Move Down", systemImage: "arrow.down") { model.move(entry, by: 1) }
                    }
                    if model.canPairWithNext(entry) {
                        Button("Superset with Next", systemImage: "link") { model.pairWithNext(entry) }
                    }
                    if entry.supersetGroup != nil {
                        Button("Remove from Superset", systemImage: "minus.circle") { model.unpair(entry) }
                    }
                    Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                        model.remove(entry)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                }
            }

            if let tag = model.supersetTag(for: entry) {
                Label("Superset \(tag.letter) · \(tag.position) of \(tag.count)", systemImage: "link")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            if let note = entry.exercise?.personalNotes.nilIfBlank {
                Button { editingNote = true } label: {
                    Label(note, systemImage: "note.text")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Edit note")
            }

            // Rest and progression shape the next session, not one already done. Holds only
            // progress on their own in the gym: a Kineto dose is the physiotherapist's call.
            if let exercise = entry.exercise, !model.isHistory {
                restMenu(for: exercise)
                if !entry.isDurationBased || entry.workout?.section == .gym {
                    ProgressionMenu(entry: entry, exercise: exercise, model: model, unit: unit)
                }
            }

            VStack(spacing: 0) {
                header
                let sets = entry.orderedSets
                let labels = SetKind.labels(for: sets.map(\.kind))
                let records = entry.recordKinds()
                let isDurationBased = entry.isDurationBased
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                    if isDurationBased {
                        HoldSetRowView(
                            entry: set,
                            label: labels[index],
                            isStriped: index.isMultiple(of: 2),
                            isRecord: !records[index].isEmpty
                        ) {
                            model.toggle(set)
                        }
                        .contextMenu {
                            Button("Duplicate Set", systemImage: "plus.square.on.square") { model.duplicate(set) }
                            Button("Delete Set", systemImage: "trash", role: .destructive) { model.delete(set) }
                        }
                    } else {
                        SetRowView(
                            entry: set,
                            label: labels[index],
                            unit: unit,
                            effortScale: effortScale,
                            isStriped: index.isMultiple(of: 2),
                            isRecord: !records[index].isEmpty
                        ) {
                            model.toggle(set)
                        }
                        .contextMenu {
                            Button("Plate Calculator", systemImage: "circle.grid.2x1") { plateTargetKg = set.weightKg }
                            Button("Duplicate Set", systemImage: "plus.square.on.square") { model.duplicate(set) }
                            Button("Delete Set", systemImage: "trash", role: .destructive) { model.delete(set) }
                        }
                    }
                }
            }
            .padding(.horizontal, -16)

            Button {
                model.addSet(to: entry)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(CardButtonStyle())
        }
        // Sits in the screen margin, so the cards of one superset read as joined.
        .overlay(alignment: .leading) {
            if model.supersetTag(for: entry) != nil {
                Capsule().fill(.orange).frame(width: 4).offset(x: -11)
            }
        }
        .sheet(isPresented: showingPlates) {
            PlateCalculatorView(unit: unit, targetKg: plateTargetKg ?? 0)
        }
        .sheet(isPresented: $swapping) {
            ExercisePickerView(single: true) { picked in
                if let exercise = picked.first { model.swap(entry, to: exercise) }
            }
        }
        .sheet(isPresented: $editingNote) {
            if let exercise = entry.exercise { ExerciseNoteEditor(exercise: exercise) }
        }
        .sheet(isPresented: $showingDetails) {
            if let exercise = entry.exercise {
                ExerciseInfoSheet(exercise: exercise, section: entry.workout?.section ?? .gym, isDurationBased: entry.isDurationBased)
            }
        }
    }

    /// Per-exercise because rest needs differ wildly: 3 min after heavy squats, 45 s after curls.
    private func restMenu(for exercise: Exercise) -> some View {
        let fallback: Int = model.defaultRestSeconds
        let current: String = exercise.restSeconds.map(RestDuration.label) ?? "\(RestDuration.label(fallback)) (default)"
        return Menu {
            Button("Default (\(RestDuration.label(fallback)))") { exercise.restSeconds = nil }
            ForEach(RestDuration.choices, id: \.self) { seconds in
                Button(RestDuration.label(seconds)) { exercise.restSeconds = seconds }
            }
            Button("Off") { exercise.restSeconds = 0 }
        } label: {
            Label("Rest Timer: \(current)", systemImage: "timer")
                .foregroundStyle(Theme.accent)
        }
    }

    private var header: some View {
        HStack {
            Text("SET").frame(width: 56)
            if entry.isDurationBased {
                Text("REPS").frame(maxWidth: .infinity)
                Text("HOLD").frame(maxWidth: .infinity)
            } else {
                Text(unit.rawValue.uppercased()).frame(maxWidth: .infinity)
                Text("REPS").frame(maxWidth: .infinity)
                if effortScale != .off {
                    Text(effortScale.title).frame(width: EffortChip.width)
                }
            }
            Image(systemName: "checkmark").frame(width: 64)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(height: 32)
    }
}
