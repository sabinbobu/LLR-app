import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lbs

    var id: String { rawValue }

    static let kgPerLb = 0.45359237

    func fromKg(_ kg: Double) -> Double { self == .kg ? kg : kg / Self.kgPerLb }
    func toKg(_ value: Double) -> Double { self == .kg ? value : value * Self.kgPerLb }

    /// Fixed "." separator instead of locale formatting so stored text round-trips through `parse`.
    func format(kg: Double) -> String {
        let value = (fromKg(kg) * 10).rounded() / 10
        return value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    /// Decimal pads in comma locales emit ",", so accept both separators.
    static func parse(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
    }
}
