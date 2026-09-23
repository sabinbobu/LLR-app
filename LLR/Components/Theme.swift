import SwiftUI

enum Theme {
    static let accent = Color(red: 0.0, green: 0.55, blue: 1.0)
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

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(Theme.card.opacity(configuration.isPressed ? 0.6 : 1), in: RoundedRectangle(cornerRadius: 14))
    }
}
