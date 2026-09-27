import SwiftData
import XCTest
@testable import LLR

@MainActor
final class MeasurementSeederTests: XCTestCase {
    private var context: ModelContext!
    private var defaults: UserDefaults!
    private let suiteName = "MeasurementSeederTests"

    override func setUp() async throws {
        let container = try ModelContainer(
            for: BodyMeasurement.self, ProgressPhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testSeedsBothValuesWhenOnboardingSetThem() throws {
        defaults.set(82.5, forKey: StorageKey.bodyWeightKg)
        defaults.set(180, forKey: StorageKey.heightCm)

        MeasurementSeeder.seedIfNeeded(in: context, defaults: defaults)

        let measurements = try context.fetch(FetchDescriptor<BodyMeasurement>())
        XCTAssertEqual(measurements.count, 2)
        XCTAssertTrue(measurements.contains { $0.kind == .bodyWeight && $0.value == 82.5 })
        XCTAssertTrue(measurements.contains { $0.kind == .height && $0.value == 180 })
    }

    func testNeverSeedsAValueOnboardingNeverActuallySet() throws {
        // Neither key was written — only reading a bound @AppStorage default would fake this.
        MeasurementSeeder.seedIfNeeded(in: context, defaults: defaults)
        XCTAssertTrue(try context.fetch(FetchDescriptor<BodyMeasurement>()).isEmpty)
    }

    func testRunningTwiceNeverDuplicatesEntries() throws {
        defaults.set(82.5, forKey: StorageKey.bodyWeightKg)
        MeasurementSeeder.seedIfNeeded(in: context, defaults: defaults)
        MeasurementSeeder.seedIfNeeded(in: context, defaults: defaults)
        XCTAssertEqual(try context.fetch(FetchDescriptor<BodyMeasurement>()).count, 1)
    }
}
