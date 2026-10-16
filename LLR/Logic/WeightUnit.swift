import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lbs

    var id: String { rawValue }

    static let kgPerLb = 0.45359237

    func fromKg(_ kg: Double) -> Double { self == .kg ? kg : kg / Self.kgPerLb }
    func toKg(_ value: Double) -> Double { self == .kg ? value : value * Self.kgPerLb }

    /// Fixed "." separator instead of locale formatting so stored text round-trips through `parse`.
    func format(kg: Double) -> String { Self.oneDecimal(fromKg(kg)) }

    /// Decimal pads in comma locales emit ",", so accept both separators. "inf", "nan" and runaway
    /// digit strings parse as Doubles too; they are rejected here so they never reach the store.
    static func parse(_ text: String) -> Double? {
        guard let value = Double(text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)),
              value.isFinite, abs(value) <= InputLimits.maxAmount
        else { return nil }
        return value
    }

    /// At most one decimal, a trailing ".0" dropped. `%.0f` rather than `Int(_:)`, which traps on a
    /// value past Int's range.
    static func oneDecimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        // -0.0 would print as "-0".
        let shown = rounded == 0 ? 0 : rounded
        return String(format: shown == shown.rounded() ? "%.0f" : "%.1f", shown)
    }
}
