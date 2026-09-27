import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var id: UUID
    // Stored as a raw string so a future kind can be added without a schema version bump.
    var kindRaw: String
    /// Canonical unit per `kind.dimension`: kg for mass, cm for length, raw percent for percent.
    var value: Double
    var takenAt: Date

    init(kind: MeasurementKind, value: Double, takenAt: Date = .now) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.value = value
        self.takenAt = takenAt
    }
}

extension BodyMeasurement {
    var kind: MeasurementKind {
        get { MeasurementKind(rawValue: kindRaw) ?? .bodyWeight }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class ProgressPhoto {
    var id: UUID
    var takenAt: Date
    // External storage: SwiftData keeps large blobs out of the main store file instead of bloating it.
    @Attribute(.externalStorage) var imageData: Data

    init(imageData: Data, takenAt: Date = .now) {
        self.id = UUID()
        self.imageData = imageData
        self.takenAt = takenAt
    }
}
