import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw == "gym" }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if workouts.isEmpty {
                        EmptyStateCard(systemImage: "dumbbell", message: "Your finished workouts show up here")
                    } else {
                        ForEach(workouts) { workout in
                            NavigationLink(value: workout) {
                                WorkoutCard(workout: workout)
                            }
                            .buttonStyle(.plain)
                            .workoutActions(workout)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationDestination(for: Workout.self) { WorkoutDetailView(workout: $0) }
        }
    }
}
