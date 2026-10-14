import SwiftUI

enum ButtonEmphasis {
    case primary, secondary, quiet, destructive
}

/// The four button roles share height, font and pressed state; only colour and weight differ,
/// so a screen's main action looks the same wherever it appears.
struct RoleButtonStyle: ButtonStyle {
    let role: ButtonEmphasis

    func makeBody(configuration: Configuration) -> some View {
        RoleButtonBody(role: role, configuration: configuration)
    }
}

// A separate View because @Environment only resolves inside the view hierarchy, not on a style value.
private struct RoleButtonBody: View {
    let role: ButtonEmphasis
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card)
        let pressed: Double = configuration.isPressed ? 0.8 : 1
        return configuration.label
            .font(.headline)
            .foregroundStyle(labelColor)
            .frame(maxWidth: .infinity, minHeight: role == .quiet ? 44 : 52)
            .background(fillColor.opacity(pressed), in: shape)
    }

    // Disabled is grey-on-grey: white on a light grey fill is unreadable for a label that says what to do next.
    private var labelColor: Color {
        if !isEnabled { return Color.secondary }
        switch role {
        case .primary, .destructive: return Color.white
        case .secondary, .quiet: return Theme.accent
        }
    }

    private var fillColor: Color {
        if !isEnabled { return role == .quiet ? Color.clear : Color(.systemGray5) }
        switch role {
        case .primary: return Theme.primaryFill
        case .secondary: return Theme.accent.opacity(0.15)
        case .quiet: return Color.clear
        case .destructive: return Theme.destructiveFill
        }
    }
}

extension ButtonStyle where Self == RoleButtonStyle {
    static var primaryRole: RoleButtonStyle { RoleButtonStyle(role: .primary) }
    static var secondaryRole: RoleButtonStyle { RoleButtonStyle(role: .secondary) }
    static var quietRole: RoleButtonStyle { RoleButtonStyle(role: .quiet) }
    static var destructiveRole: RoleButtonStyle { RoleButtonStyle(role: .destructive) }
}
