import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab = .home
    @State private var presenter = ActiveWorkoutPresenter()
    // Section-agnostic like the Workout tab: one workout at a time, gym or Kineto.
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]

    var body: some View {
        Group {
            switch tab {
            case .home: HomeView()
            case .workout: WorkoutTabView()
            case .fuel: FuelView()
            case .profile: ProfileView()
            }
        }
        // The floating bar sits over the scroll view's edge, so the last row ended right against it.
        // Extra scroll-content space lets every tab screen (and the screens pushed from it) scroll
        // its last row clear of the bar.
        .contentMargins(.bottom, 32, for: .scrollContent)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if let current = unfinished.first, presenter.presented == nil {
                    MiniWorkoutBar(workout: current, timer: .shared) { presenter.present(current) }
                }
                FloatingTabBar(selection: $tab)
            }
        }
        .fullScreenCover(item: $presenter.presented, onDismiss: presenter.coverDismissed) { workout in
            ActiveWorkoutView(workout: workout) { presenter.pendingSummary = $0 }
        }
        .sheet(item: $presenter.summary, onDismiss: presenter.summaryDismissed) { WorkoutSummaryView(workout: $0) }
        // Catches anything Finish's own sync could have missed (e.g. a Lock Screen set logged
        // right before backgrounding) so the widget is never more than one background away from fresh.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { TrainingSnapshotSync.sync(context: context) }
        }
        // Outermost, so the workout cover and the summary sheet see it too: presented content
        // inherits only what is set outside the modifier that presents it. The summary reads it
        // for the cooldown offer, and crashed on every Finish while this sat inside.
        .environment(presenter)
    }
}
