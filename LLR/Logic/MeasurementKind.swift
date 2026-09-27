import Foundation

enum MeasurementDimension {
    case mass, length, percent
}

enum MeasurementKind: String, CaseIterable, Identifiable {
    case bodyWeight, bodyFat, leanBodyMass, height
    case neck, shoulders, chest, waist, hips
    case leftBicep, rightBicep, leftForearm, rightForearm
    case leftThigh, rightThigh, leftCalf, rightCalf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bodyWeight: "Body Weight"
        case .bodyFat: "Body Fat"
        case .leanBodyMass: "Lean Body Mass"
        case .height: "Height"
        case .neck: "Neck"
        case .shoulders: "Shoulders"
        case .chest: "Chest"
        case .waist: "Waist"
        case .hips: "Hips"
        case .leftBicep: "Left Bicep"
        case .rightBicep: "Right Bicep"
        case .leftForearm: "Left Forearm"
        case .rightForearm: "Right Forearm"
        case .leftThigh: "Left Thigh"
        case .rightThigh: "Right Thigh"
        case .leftCalf: "Left Calf"
        case .rightCalf: "Right Calf"
        }
    }

    var dimension: MeasurementDimension {
        switch self {
        case .bodyWeight, .leanBodyMass: .mass
        case .bodyFat: .percent
        default: .length
        }
    }

    /// A body-map muscle to crop the icon from, where one applies; nil falls back to `systemImage`.
    var muscle: MuscleGroup? {
        switch self {
        case .neck: .neck
        case .shoulders: .shoulders
        case .chest: .chest
        case .leftBicep, .rightBicep: .biceps
        case .leftForearm, .rightForearm: .forearms
        case .leftThigh, .rightThigh: .quadriceps
        case .leftCalf, .rightCalf: .calves
        default: nil
        }
    }

    var systemImage: String {
        switch self {
        case .bodyWeight: "scalemass"
        case .bodyFat: "percent"
        case .leanBodyMass: "figure.arms.open"
        case .height: "ruler"
        case .waist, .hips: "figure.stand"
        default: "figure.arms.open"
        }
    }

    func format(_ canonicalValue: Double, unit: WeightUnit) -> String {
        switch dimension {
        case .mass: "\(unit.format(kg: canonicalValue)) \(unit.rawValue)"
        case .length: "\(unit.formatLength(cm: canonicalValue)) \(unit.lengthSuffix)"
        case .percent: "\(Int(canonicalValue.rounded()))%"
        }
    }
}

extension WeightUnit {
    /// Measurements follow the weight unit — cm for kg users, inches for lbs users — so there's no
    /// separate length-unit setting to add.
    var lengthSuffix: String { self == .kg ? "cm" : "in" }

    static let cmPerInch = 2.54

    func fromCm(_ cm: Double) -> Double { self == .kg ? cm : cm / Self.cmPerInch }
    func toCm(_ value: Double) -> Double { self == .kg ? value : value * Self.cmPerInch }

    func formatLength(cm: Double) -> String {
        let value = (fromCm(cm) * 10).rounded() / 10
        return value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
