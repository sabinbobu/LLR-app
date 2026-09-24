import SwiftUI

enum Theme {
    // #2563EB from the routine designs; lifted to #3B82F6 in dark mode, where the light value is too dim on black.
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.231, green: 0.510, blue: 0.965, alpha: 1)
            : UIColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 1)
    })
    static let accentSoft = accent.opacity(0.08)
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let field = Color(.tertiarySystemGroupedBackground)
    static let card = Color(.secondarySystemBackground)
    static let border = Color(.systemGray5)
    static let completedRow = Color.green.opacity(0.3)
    static let completedCheck = Color(red: 0.30, green: 0.78, blue: 0.35)
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                (isEnabled ? Theme.accent : Color(.systemGray3)).opacity(configuration.isPressed ? 0.8 : 1),
                in: RoundedRectangle(cornerRadius: 16)
            )
    }
}

/// The routine and picker sheets' main action. Disabled is grey-on-grey rather than
/// white-on-light-grey, which is unreadable for a label that explains what to do next.
struct SheetButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Color.white : Color.secondary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                (isEnabled ? Theme.accent : Color(.systemGray5)).opacity(configuration.isPressed ? 0.8 : 1),
                in: RoundedRectangle(cornerRadius: 14)
            )
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(Theme.card.opacity(configuration.isPressed ? 0.6 : 1), in: RoundedRectangle(cornerRadius: 14))
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        background(Theme.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Theme.border))
    }
}

extension Text {
    func sectionLabel() -> some View {
        font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}
