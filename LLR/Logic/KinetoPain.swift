import Foundation

/// Pure pain-tracking rules, kept separate from SwiftData so they're trivially testable. The
/// flag threshold is Ostelo 2008's minimal-important-change for a 0–10 pain scale (2 points);
/// the app surfaces the flag and tells the user to raise it with their physiotherapist — it
/// never decides anything about the plan itself.
enum KinetoPain {
    static let flagThreshold = 2

    static func worsened(before: Int?, after: Int?) -> Bool {
        guard let before, let after else { return false }
        return after - before >= flagThreshold
    }

    /// True when back or leg pain rose by at least the minimal-important-change, or symptoms
    /// spread further down the leg — the disc warning sign a pain-score delta alone can miss.
    static func shouldFlag(backBefore: Int?, backAfter: Int?, legBefore: Int?, legAfter: Int?, symptomsSpread: Bool?) -> Bool {
        symptomsSpread == true
            || worsened(before: backBefore, after: backAfter)
            || worsened(before: legBefore, after: legAfter)
    }
}
