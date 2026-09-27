import SwiftUI

enum AppTab: CaseIterable {
    case home, workout, fuel, profile

    var title: String {
        switch self {
        case .home: "Home"
        case .workout: "Workout"
        case .fuel: "Fuel"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .workout: "dumbbell"
        case .fuel: "fork.knife"
        case .profile: "person"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon).font(.title2).frame(height: 28)
                        Text(tab.title).font(.caption)
                    }
                    .foregroundStyle(selection == tab ? Theme.accent : Color.primary)
                    // Four items at 100 pt overflow a 393 pt-wide iPhone once the bar's padding is added.
                    .frame(width: 84, height: 60)
                    .background {
                        if selection == tab {
                            Capsule().fill(Color(.systemGray5))
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.border))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 4)
        .padding(.bottom, 4)
        .sensoryFeedback(.selection, trigger: selection)
    }
}
