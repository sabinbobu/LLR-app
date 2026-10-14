import SwiftUI

/// The one card look: filled, hairline border, shared padding. `emphasised` is for hero cards
/// and steps up the radius and border so they read as the focus of a screen.
struct CardStyle: ViewModifier {
    var emphasised: Bool = false

    func body(content: Content) -> some View {
        let radius: CGFloat = emphasised ? Theme.Radius.hero : Theme.Radius.card
        let shape = RoundedRectangle(cornerRadius: radius)
        let border: Color = emphasised ? Theme.accent.opacity(0.5) : Theme.border
        return content
            .padding(Theme.cardPadding)
            .background(Theme.card, in: shape)
            .overlay(shape.stroke(border))
    }
}

extension View {
    func card(emphasised: Bool = false) -> some View {
        modifier(CardStyle(emphasised: emphasised))
    }
}
