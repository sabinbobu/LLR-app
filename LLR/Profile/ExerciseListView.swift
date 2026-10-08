import SwiftData
import SwiftUI

struct ExerciseListView: View {
    @Environment(\.modelContext) private var context
    // Gym-facing: user-made Kineto exercises live in the Kineto catalog.
    @Query(filter: #Predicate<Exercise> { $0.sectionRaw == "gym" }, sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""

    private var filtered: [Exercise] {
        let matches = search.isEmpty ? exercises : exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
        return ExerciseFavourites.favouritesFirst(matches, isFavourite: \.isFavourite)
    }

    var body: some View {
        List(filtered) { exercise in
            NavigationLink {
                ExerciseDetailView(exercise: exercise)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                        Text(exercise.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    if exercise.isFavourite {
                        Spacer()
                        Image(systemName: "star.fill").foregroundStyle(.yellow).accessibilityLabel("Favourite")
                    }
                }
            }
            .swipeActions(edge: .leading) {
                Button(exercise.isFavourite ? "Unfavourite" : "Favourite", systemImage: exercise.isFavourite ? "star.slash" : "star") {
                    exercise.isFavourite.toggle()
                }
                .tint(.yellow)
            }
            .swipeActions {
                if exercise.canDelete {
                    Button("Delete", systemImage: "trash", role: .destructive) { exercise.deleteWithMedia(from: context) }
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle("Exercises")
    }
}
