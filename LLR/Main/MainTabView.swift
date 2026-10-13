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
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if let current = unfinished.first, presenter.presented == nil {
                    MiniWorkoutBar(workout: current, timer: .shared) { presenter.present(current) }
                }
                FloatingTabBar(selection: $tab)
            }
        }
        .environment(presenter)
        .fullScreenCover(item: $presenter.presented, onDismiss: presenter.coverDismissed) { workout in
            ActiveWorkoutView(workout: workout) { presenter.pendingSummary = $0 }
        }
        .sheet(item: $presenter.summary, onDismiss: presenter.summaryDismissed) { WorkoutSummaryView(workout: $0) }
        // Catches anything Finish's own sync could have missed (e.g. a Lock Screen set logged
        // right before backgrounding) so the widget is never more than one background away from fresh.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { TrainingSnapshotSync.sync(context: context) }
        }
    }
}
