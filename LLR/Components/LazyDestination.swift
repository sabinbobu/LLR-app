import SwiftUI

/// Defers building a navigation destination until it is shown. `NavigationLink` builds its
/// destination every time the screen holding the link renders, so a destination that walks the
/// whole history ran on every Profile update, opened or not.
/// It also keeps a filtered @Query off the pushed screen's root: pushed from the Kineto hub, such a
/// root refetched on every navigation update, which triggered another update and froze the app.
struct LazyDestination<Content: View>: View {
    let build: () -> Content

    init(@ViewBuilder _ build: @escaping () -> Content) {
        self.build = build
    }

    var body: some View { build() }
}
