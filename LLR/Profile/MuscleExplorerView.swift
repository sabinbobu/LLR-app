import SwiftData
import SwiftUI

/// Browse the library from the body: tap a muscle, see what trains it.
struct MuscleExplorerView: View {
    // Gym-facing, like the exercise list this is opened from.
    @Query(filter: #Predicate<Exercise> { $0.sectionRaw == "gym" }, sort: \Exercise.name) private var exercises: [Exercise]
    @State private var selected: MuscleGroup?
    @State private var equipment: String?

    private func equipmentOptions(_ muscle: MuscleGroup) -> [String] {
        Equipment.options(in: MuscleExplorer.hits(for: muscle, in: exercises).map(\.item.equipment))
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
    }

    private var mapCard: some View {
        // Once per render: as a computed property each chip re-ran the query and the full count,
        // twice (its label and its accessibility label).
        let counts = MuscleExplorer.counts(exercises)
        return VStack(spacing: 16) {
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
        let hits = MuscleExplorer.hits(for: muscle, in: exercises, equipment: equipment)
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
        section("Main target", rows: hits.filter(\.isPrimary).map(\.item))
        section("Also trains it", rows: hits.filter { !$0.isPrimary }.map(\.item))
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
