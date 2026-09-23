import SwiftUI

struct RootView: View {
    @AppStorage(StorageKey.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        if hasOnboarded {
            MainTabView()
        } else {
            OnboardingFlow()
        }
    }
}
