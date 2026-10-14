import SwiftUI

/// Tokens for the Profile hero card. They live beside the card, not in `Theme.swift`, so the
/// design-system work can reshape that file without conflicting with this one.
extension Theme {
    /// Accent mixed about 12% into the surface, precomputed per appearance so the card gradient
    /// is a static fill (no blur, cheap to scroll past).
    static let heroTint = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.125, green: 0.158, blue: 0.220, alpha: 1)
            : UIColor(red: 0.897, green: 0.927, blue: 0.991, alpha: 1)
    })

    /// The hairline along the card's top edge: a light edge catches in dark mode, soft white in light.
    static let heroHighlight = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.14)
            : UIColor(white: 1, alpha: 0.9)
    })

    /// Dividers between stats; lighter than `border` so they stay quiet on the tinted surface.
    static let heroDivider = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.12)
            : UIColor(white: 0, alpha: 0.10)
    })

    /// Unfilled ring segments.
    static let ringTrack = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.14)
            : UIColor(white: 0, alpha: 0.09)
    })

    /// Clear in dark mode, where a shadow on a near-black page would be invisible anyway.
    static let heroShadow = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.clear
            : UIColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 0.14)
    })
}
