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

/// The Home redesign's card: a white surface lifted by a soft shadow in light mode, flat in dark
/// (where the surface is already lighter than the background), with no hairline border.
struct SurfaceCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let lit = scheme == .light
        return content
            .padding(Theme.cardPadding)
            // On the shape, not the content: a shadow on the content would be cast by every chip and tile inside.
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Theme.surface)
                    .shadow(color: .black.opacity(lit ? 0.04 : 0), radius: 1, y: 1)
                    .shadow(color: .black.opacity(lit ? 0.06 : 0), radius: 8, y: 4)
            }
    }
}

extension View {
    func card(emphasised: Bool = false) -> some View {
        modifier(CardStyle(emphasised: emphasised))
    }

    func surfaceCard() -> some View {
        modifier(SurfaceCardStyle())
    }
}
