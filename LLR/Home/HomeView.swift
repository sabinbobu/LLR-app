import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(ActiveWorkoutPresenter.self) private var presenter
    // Everything but Kineto: lifts and runs share the timeline. An OR of two sections is too slow for the type checker.
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw != "kineto" }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]
    // Section-agnostic like the Workout tab: only one workout can be in progress at a time.
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    WeekCard(
                        days: HomeModel.week(trained: starts),
                        workoutCount: HomeModel.workoutCount(in: starts)
                    )
                    startCard
                    recent
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Workout.self) { HistoryDestination(workout: $0) }
        }
    }

    private var starts: [Date] { workouts.map(\.startedAt) }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
            Text("Training").font(.largeTitle.bold())
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder private var startCard: some View {
        if let current = unfinished.first {
            StartWorkoutCard(title: "Resume workout", subtitle: current.title) { presenter.present(current) }
        } else {
            let next = HomeModel.nextUp(workouts)
            StartWorkoutCard(title: "Start workout", subtitle: nextUpSubtitle(next)) {
                presenter.present(WorkoutFactory.start(copying: next, in: context))
            }
        }
    }

    private func nextUpSubtitle(_ next: Workout?) -> String {
        guard let next, let name = HomeModel.splitName(next) else { return "Blank workout" }
        let count = next.orderedExercises.count
        return "Next up: \(name) · \(count) \(count == 1 ? "exercise" : "exercises")"
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent").font(.title2.bold())
                Spacer()
                if workouts.count > HomeModel.recentLimit {
                    NavigationLink("See all") { AllWorkoutsView(workouts: workouts) }
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
            }
            if workouts.isEmpty {
                EmptyStateCard(systemImage: "dumbbell", message: "Your finished workouts show up here")
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(workouts.prefix(HomeModel.recentLimit)) { workout in
                        NavigationLink(value: workout) { HistoryCard(workout: workout) }
                            .buttonStyle(.plain)
                            .workoutActions(workout)
                    }
                }
            }
        }
    }
}
