import SwiftUI

extension Theme {
    /// One scale for every corner; screens pick a step instead of a number.
    enum Radius {
        static let chip: CGFloat = 8
        static let field: CGFloat = 12
        static let card: CGFloat = 16
        static let hero: CGFloat = 24
    }

    /// Inner padding every card shares, so cards line up across screens.
    static let cardPadding: CGFloat = 16

    // UIColor twins exist so ThemeContrastTests can resolve each token per appearance.
    static let repeatActionUI = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1)
            : UIColor(red: 0.851, green: 0.467, blue: 0.024, alpha: 1)
    }

    // Dark text on both fills: white only reaches 2.1:1 and 3.2:1 on the amber.
    static let repeatActionLabelUI = UIColor(red: 0.110, green: 0.075, blue: 0.0, alpha: 1)

    /// Complement of the blue accent (about 41 degrees), so Repeat reads apart from Start.
    static let repeatAction = Color(uiColor: repeatActionUI)
    static let repeatActionLabel = Color(uiColor: repeatActionLabelUI)

    // White on the dark-mode accent (#3B82F6) is only 3.7:1, so filled buttons use the deeper blue in both modes.
    static let primaryFillUI = UIColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 1)
    static let primaryFill = Color(uiColor: primaryFillUI)
    static let onPrimaryFillUI = UIColor.white

    // Fixed deep red: system red with white text is only 3.6:1.
    static let destructiveFillUI = UIColor(red: 0.776, green: 0.157, blue: 0.157, alpha: 1)
    static let destructiveFill = Color(uiColor: destructiveFillUI)
}
