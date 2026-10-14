import SwiftUI

/// Press-down feedback for the whole hero card, which is a single tap target.
struct HeroCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let scale: CGFloat = configuration.isPressed ? 0.97 : 1
        let animation: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.65)
        return configuration.label
            .scaleEffect(scale)
            .animation(animation, value: configuration.isPressed)
    }
}
