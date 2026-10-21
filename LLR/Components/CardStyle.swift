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

/// Home's card: the grouped-list surface sitting on the grouped background. Light mode
/// gets a soft shadow and a hairline so the card also reads on a plain white screen (Profile);
/// in dark the surface contrast alone separates it.
struct SurfaceCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card)
        let light = scheme == .light
        return content
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: shape)
            .overlay(shape.stroke(Color.black.opacity(light ? 0.04 : 0)))
            .shadow(color: .black.opacity(light ? 0.04 : 0), radius: 1, y: 1)
            .shadow(color: .black.opacity(light ? 0.06 : 0), radius: 8, y: 4)
    }
}

extension View {
    func surfaceCard() -> some View {
        modifier(SurfaceCardStyle())
    }
}
