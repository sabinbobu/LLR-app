import SwiftUI

/// Home and Profile list lifts and runs together; these two pick the right card and detail screen.
struct HistoryCard: View {
    let workout: Workout

    var body: some View {
        if workout.isRun { RunCard(workout: workout) } else { WorkoutCard(workout: workout) }
    }
}

struct HistoryDestination: View {
    let workout: Workout

    var body: some View {
        if workout.isRun { RunDetailView(workout: workout) } else { WorkoutDetailView(workout: workout) }
    }
}
