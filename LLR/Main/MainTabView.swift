import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab = .home

    var body: some View {
        Group {
            switch tab {
            case .home: HomeView()
            case .workout: WorkoutTabView()
            case .profile: ProfileView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selection: $tab)
        }
        // Catches anything Finish's own sync could have missed (e.g. a Lock Screen set logged
        // right before backgrounding) so the widget is never more than one background away from fresh.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { TrainingSnapshotSync.sync(context: context) }
        }
    }
}
