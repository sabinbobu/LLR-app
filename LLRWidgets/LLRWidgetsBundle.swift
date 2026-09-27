import SwiftUI
import WidgetKit

@main
struct LLRWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivity()
        StreakWidget()
    }
}

extension Color {
    // Same values as the app's Theme.accent; the extension can't see the app's code.
    static let llrAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.231, green: 0.510, blue: 0.965, alpha: 1)
            : UIColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 1)
    })
}
