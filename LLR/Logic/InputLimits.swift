import Foundation

/// Bounds on numbers typed in or read from a file. Past them a value is a typo or a corrupt row, and
/// left in it overflows Int arithmetic (session totals, volume) or traps in `Int(_:)` when shown.
enum InputLimits {
    /// Weights, grams, calories and tape sizes all sit far below this.
    static let maxAmount = 100_000.0
    static let maxReps = 10_000
    /// A day: no hold or timed set runs longer.
    static let maxSeconds = 86_400
    /// Sets one pick may add: "100" typed for "10" still finishes, a mistyped million doesn't freeze the app.
    static let maxSets = 50

    /// A whole number in 0...max, or nil, so a field keeps its last good value.
    static func count(_ text: String, max: Int = maxReps) -> Int? {
        guard let value = Int(text.trimmingCharacters(in: .whitespaces)), (0...max).contains(value) else { return nil }
        return value
    }
}
