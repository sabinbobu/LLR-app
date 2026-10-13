import SwiftData
import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    // User-made Kineto exercises belong to the Kineto catalog only.
    @Query(filter: #Predicate<Exercise> { $0.sectionRaw == "gym" }, sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var muscle: String?
    @State private var equipment: String?
    /// Tap order, so exercises land in the workout or routine in the order they were chosen.
    @State private var picked: [UUID] = []
    @State private var creating = false
    @State private var inspecting: Exercise?
    /// Picking a stand-in for one exercise: a tap replaces the choice instead of adding to it.
    var single = false
    /// The muscle filter the picker opens with; "Show all" clears it. Nil opens unfiltered.
    let initialMuscle: String?
    let onAdd: ([Exercise]) -> Void

    init(single: Bool = false, initialMuscle: String? = nil, onAdd: @escaping ([Exercise]) -> Void) {
        self.single = single
        self.initialMuscle = initialMuscle
        self.onAdd = onAdd
        _muscle = State(initialValue: initialMuscle)
    }

    private var muscleOptions: [String] { Array(Set(exercises.map(\.muscleGroup))).sorted() }
    private var equipmentOptions: [String] { Equipment.options(in: exercises.map(\.equipment)) }

    private var filtered: [Exercise] {
        var result: [Exercise] = exercises
        if !search.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(search) }
        }
        if let muscle {
            result = result.filter { $0.muscleGroup == muscle }
        }
        if let equipment {
            result = result.filter { Equipment.matches($0.equipment, filter: equipment) }
        }
        return result
    }

    private struct ListSection {
        let title: String
        let rows: [Exercise]
    }

    /// Browsing shows the curated Popular set above the full A–Z list; any search or filter
    /// collapses to one section of matches.
    private var sections: [ListSection] {
        guard search.isEmpty, muscle == nil, equipment == nil else {
            return [ListSection(title: muscle ?? "Results", rows: ExerciseFavourites.favouritesFirst(filtered, isFavourite: \.isFavourite))]
        }
        var builtIns: [String: Exercise] = [:]
        for exercise in exercises where !exercise.isCustom {
            builtIns[exercise.name] = exercise
        }
        let popular = ExerciseLibrary.popular.compactMap { builtIns[$0] }
        let all = ListSection(title: "All exercises", rows: exercises)
        let favourites = exercises.filter(\.isFavourite)
        var result: [ListSection] = []
        if !favourites.isEmpty { result.append(ListSection(title: "Favourites", rows: favourites)) }
        if !popular.isEmpty { result.append(ListSection(title: "Popular", rows: popular)) }
        return result + [all]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        FilterChip(title: "Equipment", options: equipmentOptions, selection: $equipment)
                        FilterChip(title: "Muscle", options: muscleOptions, selection: $muscle)
                        if initialMuscle != nil, muscle == initialMuscle {
                            Button("Show all") { muscle = nil }
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    .padding(.bottom, 12)

                    ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                        header(section.title, showsSelection: index == 0)
                        results(section.rows)
                            .padding(.bottom, 12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Theme.background)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
            .safeAreaInset(edge: .bottom) { addBar }
            .navigationTitle(single ? "Swap Exercise" : "Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    // An HStack rather than a Label: iOS 26 toolbars collapse a Label to its icon alone.
                    Button { creating = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Custom")
                        }
                    }
                    .accessibilityLabel("Create custom exercise")
                }
            }
            .sheet(isPresented: $creating) {
                ExerciseEditorView(section: .gym, initialName: search) { picked.append($0.id) }
            }
            .sheet(item: $inspecting) { exercise in
                NavigationStack { ExerciseDetailView(exercise: exercise, showsDoneButton: true) }
            }
        }
    }

    private func header(_ title: String, showsSelection: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            Spacer()
            if showsSelection && !picked.isEmpty && !single {
                Text("\(picked.count) selected")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func results(_ rows: [Exercise]) -> some View {
        if rows.isEmpty {
            Text("No exercises match. Try another search, or add a custom exercise.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(24)
                .cardStyle(cornerRadius: 14)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(rows) { exercise in
                    ExercisePickerRow(
                        exercise: exercise,
                        isSelected: picked.contains(exercise.id),
                        onToggle: { toggle(exercise) },
                        onInfo: { inspecting = exercise }
                    )
                    if exercise.id != rows.last?.id {
                        Divider()
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
        }
    }

    private var addBar: some View {
        Button {
            onAdd(picked.compactMap { id in exercises.first { $0.id == id } })
            dismiss()
        } label: {
            if picked.isEmpty {
                Text(single ? "Select an exercise" : "Select exercises to add")
            } else if single {
                Text("Swap")
            } else {
                Text("Add ^[\(picked.count) exercise](inflect: true)")
            }
        }
        .buttonStyle(SheetButtonStyle())
        .disabled(picked.isEmpty)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .overlay(alignment: .top) { Divider() }
    }

    private func toggle(_ exercise: Exercise) {
        if single {
            picked = picked == [exercise.id] ? [] : [exercise.id]
        } else if let index = picked.firstIndex(of: exercise.id) {
            picked.remove(at: index)
        } else {
            picked.append(exercise.id)
        }
    }
}
