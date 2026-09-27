import SwiftData
import XCTest
@testable import LLR

/// Confirms `BodyMeasurement` and `ProgressPhoto` round-trip through a container the same way
/// `Persistence.container` builds one — the two new models registered in Phase 5.
@MainActor
final class MeasurementModelsTests: XCTestCase {
    func testBothNewModelsInsertAndFetchFromTheSameContainer() throws {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self,
            Routine.self, RoutineExercise.self, RoutineSetPlan.self,
            BodyMeasurement.self, ProgressPhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        context.insert(BodyMeasurement(kind: .waist, value: 81))
        context.insert(ProgressPhoto(imageData: Data([0xFF, 0xD8, 0xFF])))
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<BodyMeasurement>()).first?.kind, .waist)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ProgressPhoto>()).first?.imageData, Data([0xFF, 0xD8, 0xFF]))
    }

    func testUnknownStoredKindRawFallsBackToBodyWeightRatherThanCrashing() {
        let measurement = BodyMeasurement(kind: .waist, value: 1)
        measurement.kindRaw = "not-a-real-kind"
        XCTAssertEqual(measurement.kind, .bodyWeight)
    }
}
