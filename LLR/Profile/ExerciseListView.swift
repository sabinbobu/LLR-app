import SwiftData
import SwiftUI

struct ExerciseListView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""

    private var filtered: [Exercise] {
        search.isEmpty ? exercises : exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List(filtered) { exercise in
            NavigationLink {
                ExerciseDetailView(exercise: exercise)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                    Text(exercise.detail).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle("Exercises")
    }
}
