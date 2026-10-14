import SwiftUI

enum Theme {
    // #2563EB from the routine designs; lifted to #3B82F6 in dark mode, where the light value is too dim on black.
    static let accentUI = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.231, green: 0.510, blue: 0.965, alpha: 1)
            : UIColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 1)
    }
    static let accent = Color(uiColor: accentUI)
    static let accentSoft = accent.opacity(0.08)
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let field = Color(.tertiarySystemGroupedBackground)
    static let card = Color(.secondarySystemBackground)
    static let border = Color(.systemGray5)
    static let completedRow = Color.green.opacity(0.3)
    static let completedCheck = Color(red: 0.30, green: 0.78, blue: 0.35)

    // One fixed hue per macro, used everywhere a macro appears, so colour alone identifies it.
    static let kcal = Color(red: 1.0, green: 0.42, blue: 0.21)
    static let protein = Color(red: 0.93, green: 0.27, blue: 0.45)
    static let carbs = Color(red: 0.98, green: 0.72, blue: 0.13)
    static let fat = Color(red: 0.25, green: 0.66, blue: 0.96)
    static let over = Color.red

    /// Traffic-light reading of a 0–100 recovery percent.
    static func recoveryColor(_ percent: Double) -> Color {
        switch percent {
        case ..<40: .red
        case ..<80: .orange
        default: .green
        }
    }
}

/// Kept so existing screens compile; both now render the primary role, so their look converges.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoleButtonStyle(role: .primary).makeBody(configuration: configuration)
    }
}

struct SheetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoleButtonStyle(role: .primary).makeBody(configuration: configuration)
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
