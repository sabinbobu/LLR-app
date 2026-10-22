import SwiftData
import SwiftUI

struct HomeView: View {
    // Everything but Kineto: lifts and runs share the timeline. An OR of two sections is too slow for the type checker.
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw != "kineto" }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]
    // Section-agnostic: only one workout can be in progress at a time.
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]
    @Query private var routines: [Routine]
    @Environment(\.modelContext) private var context
    @Environment(ActiveWorkoutPresenter.self) private var presenter

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    WeekCard(workouts: workouts)
                    hero
                    recent
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Workout.self) { HistoryDestination(workout: $0) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.4)
                .foregroundStyle(.secondary)
            Text("Training").font(.largeTitle.weight(.bold))
        }
    }

    private var nextUp: Routine? { HomeModel.nextUp(routines: routines, workouts: workouts) }

    private var hero: some View {
        let title: String
        let subtitle: String
        if let current = unfinished.first {
            (title, subtitle) = ("Resume workout", current.title)
        } else if let routine = nextUp {
            let count = routine.exercises.count
            (title, subtitle) = ("Start workout", "Next up: \(routine.name.isEmpty ? "Routine" : routine.name) · \(count) \(count == 1 ? "exercise" : "exercises")")
        } else {
            (title, subtitle) = ("Start workout", "Blank workout")
        }
        return StartHero(title: title, subtitle: subtitle, action: start)
    }

    private func start() {
        if let current = unfinished.first {
            presenter.present(current)
        } else if let routine = nextUp {
            presenter.present(WorkoutFactory.start(routine: routine, in: context))
        } else {
            presenter.present(WorkoutFactory.start(copying: nil, in: context))
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent").font(.title2.weight(.bold))
                Spacer()
                if workouts.count > HomeModel.recentLimit {
                    NavigationLink { LazyDestination { AllWorkoutsView() } } label: {
                        Text("See all").font(.subheadline.weight(.semibold)).padding(.vertical, 12)
                    }
                }
            }
            if workouts.isEmpty {
                EmptyStateCard(systemImage: "dumbbell", message: "Your finished workouts show up here")
            } else {
                ForEach(workouts.prefix(HomeModel.recentLimit)) { workout in
                    NavigationLink(value: workout) { HistoryCard(workout: workout) }
                        .buttonStyle(.plain)
                        .workoutActions(workout)
                }
            }
        }
    }
}
