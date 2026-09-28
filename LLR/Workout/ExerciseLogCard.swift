import SwiftUI

struct ExerciseLogCard: View {
    let entry: WorkoutExercise
    let model: ActiveWorkoutModel
    let unit: WeightUnit
    @State private var plateTargetKg: Double?
    @State private var showingDetails = false

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
                    if entry.exercise != nil {
                        Button("Exercise Details", systemImage: "info.circle") { showingDetails = true }
                    }
                    Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                        model.remove(entry)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                }
            }

            // Rest and progression shape the next session, not one already done. A rep range is a
            // weight/reps concept, so it's hidden for duration sets, which progress manually.
            if let exercise = entry.exercise, !model.isHistory {
                restMenu(for: exercise)
                if !entry.isDurationBased { repRangeMenu(for: exercise) }
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
                            Button("Delete Set", systemImage: "trash", role: .destructive) { model.delete(set) }
                        }
                    } else {
                        SetRowView(
                            entry: set,
                            label: labels[index],
                            unit: unit,
                            isStriped: index.isMultiple(of: 2),
                            isRecord: !records[index].isEmpty
                        ) {
                            model.toggle(set)
                        }
                        .contextMenu {
                            Button("Plate Calculator", systemImage: "circle.grid.2x1") { plateTargetKg = set.weightKg }
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
        .sheet(isPresented: showingPlates) {
            PlateCalculatorView(unit: unit, targetKg: plateTargetKg ?? 0)
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

    private func repRangeMenu(for exercise: Exercise) -> some View {
        let range = exercise.repRange
        return VStack(alignment: .leading, spacing: 4) {
            Menu {
                Button("Off") { model.setRepRange(nil, for: entry) }
                ForEach(Progression.presets, id: \.self) { preset in
                    Button("\(preset.lowerBound)–\(preset.upperBound) reps") { model.setRepRange(preset, for: entry) }
                }
            } label: {
                Label("Rep Range: \(range.map { "\($0.lowerBound)–\($0.upperBound)" } ?? "Off")", systemImage: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Theme.accent)
            }
            if let range, let hint = progressionHint(for: exercise, range: range) {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func progressionHint(for exercise: Exercise, range: ClosedRange<Int>) -> String? {
        let previous = model.previousSets(for: exercise)
        let step = Progression.incrementKg(equipment: exercise.equipment, unit: unit)
        switch Progression.plan(previous: previous, range: range, incrementKg: step) {
        case .addLoad(let kg):
            return "Every set hit \(range.upperBound) last time: +\(unit.format(kg: kg)) \(unit.rawValue), back to \(range.lowerBound) reps."
        case .addReps:
            return "Same weight, one more rep per set until each reaches \(range.upperBound)."
        case nil:
            return "No working sets logged yet — this session sets the baseline."
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
            }
            Image(systemName: "checkmark").frame(width: 64)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(height: 32)
    }
}
