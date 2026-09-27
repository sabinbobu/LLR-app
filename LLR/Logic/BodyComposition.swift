import Foundation

/// Numbers derived from measurements the user already logs. Every function returns nil when an
/// input is missing, so the UI can say what to measure instead of showing a made-up value.
enum BodyComposition {
    /// NICE NG246 (2022) central-adiposity bands for waist-to-height ratio. They hold for adults with
    /// high muscle mass, which is why the Body hub leads with this rather than BMI.
    enum WaistZone: Equatable {
        case healthy, increased, high

        var title: String {
            switch self {
            case .healthy: "Healthy"
            case .increased: "Increased risk"
            case .high: "High risk"
            }
        }
    }

    static func bmi(weightKg: Double?, heightCm: Double?) -> Double? {
        guard let weightKg, let heightCm, heightCm > 0 else { return nil }
        let meters = heightCm / 100
        return weightKg / (meters * meters)
    }

    static func leanMassKg(weightKg: Double?, bodyFatPercent: Double?) -> Double? {
        guard let weightKg, let bodyFatPercent, (0..<100).contains(bodyFatPercent) else { return nil }
        return weightKg * (1 - bodyFatPercent / 100)
    }

    static func waistToHeight(waistCm: Double?, heightCm: Double?) -> Double? {
        guard let waistCm, let heightCm, heightCm > 0 else { return nil }
        return waistCm / heightCm
    }

    static func zone(forWaistToHeight ratio: Double) -> WaistZone {
        switch ratio {
        case ..<0.5: .healthy
        case ..<0.6: .increased
        default: .high
        }
    }

    /// Newest value of `kind` from any list of measurements.
    static func latest(_ kind: MeasurementKind, in measurements: [BodyMeasurement]) -> BodyMeasurement? {
        measurements.filter { $0.kind == kind }.max { $0.takenAt < $1.takenAt }
    }
}
