import SwiftUI

/// Everything behind Home's short Recent list. Rows push through the Home stack's `Workout` destination.
struct AllWorkoutsView: View {
    let workouts: [Workout]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(workouts) { workout in
                    NavigationLink(value: workout) { HistoryCard(workout: workout) }
                        .buttonStyle(.plain)
                        .workoutActions(workout)
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("All workouts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
