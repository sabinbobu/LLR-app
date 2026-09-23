import SwiftData
import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var creating = false
    let onPick: (Exercise) -> Void

    private var grouped: [(group: String, items: [Exercise])] {
        let filtered = search.isEmpty
            ? exercises
            : exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
        return Dictionary(grouping: filtered, by: \.muscleGroup)
            .map { (group: $0.key, items: $0.value) }
            .sorted { $0.group < $1.group }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.group) { section in
                    Section(section.group) {
                        ForEach(section.items) { exercise in
                            Button {
                                pick(exercise)
                            } label: {
                                HStack {
                                    Text(exercise.name).foregroundStyle(.primary)
                                    Spacer()
                                    if exercise.isCustom {
                                        Text("Custom").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
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
