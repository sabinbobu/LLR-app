import Foundation
import SwiftData

/// Turns onboarding's one-off bodyweight/height into the first `BodyMeasurement` rows. Idempotent —
/// safe to call on every launch and again right when onboarding finishes.
enum MeasurementSeeder {
    private static let seededKey = "measurementsSeeded"

    static func seedIfNeeded(in context: ModelContext, defaults: UserDefaults = .standard) {
        // The first launch runs this before onboarding has asked anything; marking it done then
        // would make the call at the end of onboarding a no-op and the answers would never land.
        guard defaults.bool(forKey: StorageKey.hasOnboarded), !defaults.bool(forKey: seededKey) else { return }
        defaults.set(true, forKey: seededKey)

        // Only present if the user actually moved the onboarding picker off its default — an
        // @AppStorage default is never written to UserDefaults just by being read.
        if let weightKg = defaults.object(forKey: StorageKey.bodyWeightKg) as? Double, weightKg > 0 {
            context.insert(BodyMeasurement(kind: .bodyWeight, value: weightKg))
        }
        if let heightCm = defaults.object(forKey: StorageKey.heightCm) as? Int, heightCm > 0 {
            context.insert(BodyMeasurement(kind: .height, value: Double(heightCm)))
        }
        try? context.save()
    }
}
