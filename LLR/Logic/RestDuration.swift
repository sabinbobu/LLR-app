import Foundation

enum RestDuration {
    static let choices = [30, 45, 60, 90, 120, 150, 180, 240, 300]
    static let defaultSeconds = 90

    /// `nil` override = inherit the global default; `0` = timer off for this exercise.
    static func resolve(override: Int?, defaultSeconds: Int) -> Int? {
        let seconds = override ?? defaultSeconds
        return seconds > 0 ? seconds : nil
    }

    static func label(_ seconds: Int) -> String {
        guard seconds > 0 else { return "Off" }
        let (m, s) = (seconds / 60, seconds % 60)
        switch (m, s) {
        case (0, _): return "\(s)s"
        case (_, 0): return "\(m)min"
        default: return "\(m)min \(s)s"
        }
    }
}
