import SwiftData
import SwiftUI

/// Every finished lift and run; Home itself only previews the latest few.
struct AllWorkoutsView: View {
    // Same filter as HomeView. Push this through LazyDestination: a filtered @Query on a pushed root froze the app (#65).
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw != "kineto" }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(workouts) { workout in
                    NavigationLink(value: workout) { HistoryCard(workout: workout) }
                        .buttonStyle(.plain)
                        .workoutActions(workout)
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle("All workouts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
