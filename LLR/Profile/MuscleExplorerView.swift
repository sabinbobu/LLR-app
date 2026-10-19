import SwiftData
import SwiftUI

/// Browse the library from the body: tap a muscle, see what trains it.
struct MuscleExplorerView: View {
    /// Handed down by the exercise list rather than queried here: a second @Query for the same rows,
    /// pushed from that list, kept the two re-rendering each other and pinned the main thread at 100%.
    let exercises: [Exercise]
    @State private var selected: MuscleGroup?
    @State private var equipment: String?
    /// Plain copies of the library, made once per visit. Counts, hits and the equipment menu each read
    /// every row's muscle and equipment arrays, and doing that off 400-odd SwiftData models on every
    /// tap held up the main thread.
    @State private var rows: [Row] = []
    @State private var counts: [MuscleGroup: Int] = [:]

    private struct Row: MuscleTargeting, Identifiable {
        let id: UUID
        let exercise: Exercise
        let muscleGroup: String
        let secondaryMuscles: [String]
        let equipment: [String]
        let isFavourite: Bool

        init(_ exercise: Exercise) {
            id = exercise.id
            self.exercise = exercise
            muscleGroup = exercise.muscleGroup
            secondaryMuscles = exercise.secondaryMuscles
            equipment = exercise.equipment
            isFavourite = exercise.isFavourite
        }
    }

    private func equipmentOptions(_ muscle: MuscleGroup) -> [String] {
        Equipment.options(in: MuscleExplorer.hits(for: muscle, in: rows).map(\.item.equipment))
    }

    /// On every appearance too: coming back from an exercise page may have changed its favourite star.
    private func refresh() {
        rows = exercises.map(Row.init)
        counts = MuscleExplorer.counts(rows)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                mapCard
                if let selected {
                    results(selected)
                } else {
                    Text("Tap a muscle to see the exercises that train it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle("Muscles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refresh)
        .onChange(of: exercises) { refresh() }
    }

    private var mapCard: some View {
        VStack(spacing: 16) {
            BodyMapView(tint: { groups in
                selected.map(groups.contains) == true ? Theme.accent : nil
            }, onTap: { side, point in
                select(MuscleExplorer.selection(tapping: MuscleExplorer.groups(at: point, side: side), current: selected))
            })
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            // The chips below offer the same choices to VoiceOver, by name.
            .accessibilityHidden(true)

            FlowLayout(spacing: 8) {
                ForEach(MuscleExplorer.muscles) { muscle in
                    chip(muscle, count: counts[muscle] ?? 0)
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func chip(_ muscle: MuscleGroup, count: Int) -> some View {
        let isOn = selected == muscle
        return Button {
            select(isOn ? nil : muscle)
        } label: {
            HStack(spacing: 4) {
                Text(muscle.rawValue)
                Text("\(count)").foregroundStyle(isOn ? Color.white.opacity(0.8) : Color.secondary)
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(isOn ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(isOn ? Theme.accent : Theme.field, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(muscle.rawValue), \(count) exercises")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    @ViewBuilder
    private func results(_ muscle: MuscleGroup) -> some View {
        let options = equipmentOptions(muscle)
        let hits = MuscleExplorer.hits(for: muscle, in: rows, equipment: equipment)
        HStack {
            Text("Exercises for \(muscle.rawValue)").font(.headline)
            Spacer()
            if options.count > 1 {
                FilterChip(title: "Equipment", options: options, selection: $equipment)
            }
        }
        if hits.isEmpty {
            EmptyStateCard(systemImage: "magnifyingglass", message: "No exercises match")
        }
        section("Main target", rows: hits.filter(\.isPrimary).map(\.item.exercise))
        section("Also trains it", rows: hits.filter { !$0.isPrimary }.map(\.item.exercise))
    }

    @ViewBuilder
    private func section(_ title: String, rows: [Exercise]) -> some View {
        if !rows.isEmpty {
            Text("\(title) · \(rows.count)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            LazyVStack(spacing: 0) {
                ForEach(rows) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        row(exercise)
                    }
                    .buttonStyle(.plain)
                    if exercise.id != rows.last?.id {
                        Divider()
                    }
                }
            }
            .cardStyle(cornerRadius: 14)
        }
    }

    private func row(_ exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(exercise.name).font(.callout.weight(.medium))
                    if exercise.isFavourite {
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                            .accessibilityLabel("Favourite")
                    }
                }
                Text(exercise.detail).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }

    /// A filter picked for one muscle may match nothing under the next, so it doesn't carry over.
    private func select(_ muscle: MuscleGroup?) {
        selected = muscle
        equipment = nil
    }
}
