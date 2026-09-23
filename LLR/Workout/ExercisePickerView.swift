import SwiftData
import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var muscle: String?
    @State private var equipment: String?
    @State private var creating = false
    let onPick: (Exercise) -> Void

    private var muscleOptions: [String] { Array(Set(exercises.map(\.muscleGroup))).sorted() }
    private var equipmentOptions: [String] { Equipment.allTags(in: exercises.map(\.name)) }

    private var filtered: [Exercise] {
        var result: [Exercise] = exercises
        if !search.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(search) }
        }
        if let muscle {
            result = result.filter { $0.muscleGroup == muscle }
        }
        if let equipment {
            result = result.filter { Equipment.tag(for: $0.name) == equipment }
        }
        return result
    }

    private var listTitle: String {
        muscle ?? (search.isEmpty && equipment == nil ? "Popular Exercises" : "Results")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 10) {
                        FilterChip(title: "All Equipment", options: equipmentOptions, selection: $equipment)
                        FilterChip(title: "All Muscles", options: muscleOptions, selection: $muscle)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
                Section(listTitle) {
                    ForEach(filtered) { exercise in
                        Button {
                            pick(exercise)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "dumbbell.fill")
                                    .frame(width: 40, height: 40)
                                    .overlay(Circle().stroke(Theme.border))
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name).foregroundStyle(.primary)
                                    Text(exercise.muscleGroup).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if exercise.isCustom {
                                    Text("Custom").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercise")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") { creating = true }
                }
            }
            .sheet(isPresented: $creating) {
                CreateExerciseView(initialName: search) { pick($0) }
            }
        }
    }

    private func pick(_ exercise: Exercise) {
        onPick(exercise)
        dismiss()
    }
}
