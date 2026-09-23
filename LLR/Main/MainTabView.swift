import SwiftUI

struct MainTabView: View {
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
    }
}
