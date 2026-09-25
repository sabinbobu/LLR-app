import SwiftUI

struct RoutineExerciseEditorCard: View {
    let entry: RoutineExercise
    let unit: WeightUnit
    let onRemove: () -> Void
    let onAddSet: () -> Void
    let onDeleteSet: (RoutineSetPlan) -> Void
    @State private var showingDetails = false
    @FocusState private var notesFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            titleRow

            TextField("Add notes (optional)", text: notesBinding, axis: .vertical)
                .font(.subheadline)
                .focused($notesFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .frame(minHeight: 44)
                .fieldChrome(isFocused: notesFocused)
                .padding(.horizontal, 16)

            restRow
            Divider().padding(.horizontal, 16)
            header(isDurationBased: entry.isDurationBased)

            let sets = entry.orderedSets
            let labels = SetKind.labels(for: sets.map(\.kind))
            let isDurationBased = entry.isDurationBased
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, plan in
                RoutineSetRowView(
                    plan: plan, label: labels[index], unit: unit, isDurationBased: isDurationBased,
                    canRemove: sets.count > 1
                ) {
                    onDeleteSet(plan)
                }
            }

            addSetButton
        }
        .cardStyle()
        .sheet(isPresented: $showingDetails) {
            if let exercise = entry.exercise {
                NavigationStack {
                    if entry.isDurationBased, let kinetoExercise = KinetoCatalog.exercise(named: exercise.name) {
                        KinetoExerciseDetailView(exercise: kinetoExercise)
                    } else {
                        ExerciseDetailView(exercise: exercise, showsDoneButton: true)
                    }
                }
            }
        }
    }

    private var titleRow: some View {
        HStack(spacing: 12) {
            ExerciseIconTile(size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.exercise?.name ?? "Exercise").font(.headline)
                if let muscle = entry.exercise?.muscleGroup {
                    Text(muscle).font(.footnote).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Menu {
                if entry.exercise != nil {
                    Button("Exercise Details", systemImage: "info.circle") { showingDetails = true }
                }
                Button("Remove Exercise", systemImage: "trash", role: .destructive, action: onRemove)
            } label: {
                // Explicit colour: inside a Menu label the hierarchical `.secondary` resolves against the tint.
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(.secondaryLabel))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Exercise options")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var notesBinding: Binding<String> {
        Binding(get: { entry.notes }, set: { entry.notes = $0 })
    }

    /// Unset (nil) reads as Off here, unlike the workout screen where unset means "use the global default".
    private var restRow: some View {
        HStack {
            Label {
                Text("Rest timer")
            } icon: {
                Image(systemName: "timer").foregroundStyle(.secondary)
            }
            .font(.subheadline)
            Spacer()
            Menu {
                Button("Off") { entry.restSeconds = nil }
                ForEach(RestDuration.choices, id: \.self) { seconds in
                    Button(RestDuration.label(seconds)) { entry.restSeconds = seconds }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(entry.restSeconds.map(RestDuration.label) ?? "Off")
                    Image(systemName: "chevron.down").font(.caption.weight(.bold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .padding(.leading, 14)
                .padding(.trailing, 12)
                .frame(height: 36)
                .background(Theme.accentSoft, in: Capsule())
            }
            .accessibilityLabel("Rest timer")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func header(isDurationBased: Bool) -> some View {
        HStack(spacing: 10) {
            Text("SET").frame(width: 40)
            if isDurationBased {
                Text("REPS").frame(maxWidth: .infinity)
                Text("HOLD").frame(maxWidth: .infinity)
            } else {
                Text(unit.rawValue.uppercased()).frame(maxWidth: .infinity)
                Text("REPS").frame(maxWidth: .infinity)
            }
            Color.clear.frame(width: 40, height: 1)
        }
        .font(.caption.weight(.semibold))
        .tracking(0.5)
        .foregroundStyle(.secondary)
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var addSetButton: some View {
        Button(action: onAddSet) {
            Label("Add set", systemImage: "plus")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Theme.accent.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
}
