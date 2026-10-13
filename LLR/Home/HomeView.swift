import SwiftData
import SwiftUI

struct HomeView: View {
    // Everything but Kineto: lifts and runs share the timeline. An OR of two sections is too slow for the type checker.
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw != "kineto" }, sort: \Workout.startedAt, order: .reverse)
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
                                HistoryCard(workout: workout)
                            }
                            .buttonStyle(.plain)
                            .workoutActions(workout)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationDestination(for: Workout.self) { HistoryDestination(workout: $0) }
        }
    }
}
