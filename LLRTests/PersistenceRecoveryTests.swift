import SwiftData
import XCTest
@testable import LLR

@MainActor
final class PersistenceRecoveryTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        // A space in the path, like the real store's "Application Support", so percent-encoding bugs surface.
        dir = URL.temporaryDirectory.appending(path: "Store Dir \(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func config() -> ModelConfiguration {
        ModelConfiguration(url: dir.appending(path: "test.store"))
    }

    func testOnDiskStoreSurvivesReopen() throws {
        do {
            let container = Persistence.open(config())
            container.mainContext.insert(Exercise(name: "Bench Press", muscleGroup: MuscleGroup.chest.rawValue, isCustom: true))
            try container.mainContext.save()
        }
        let reopened = Persistence.open(config())
        let names = try reopened.mainContext.fetch(FetchDescriptor<Exercise>()).map(\.name)
        XCTAssertEqual(names, ["Bench Press"])
    }

    func testUnreadableStoreIsSetAsideAndAppStillOpens() throws {
        let storeURL = dir.appending(path: "test.store")
        try Data("not a sqlite database".utf8).write(to: storeURL)

        let container = Persistence.open(config())
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Exercise>()), 0)

        let leftovers = try FileManager.default.contentsOfDirectory(atPath: dir.path(percentEncoded: false))
        XCTAssertTrue(leftovers.contains { $0.hasPrefix("test.store.corrupt-") }, "the bad file must be kept for recovery: \(leftovers)")
    }

    /// `legacy-pre-fuel.store` was written by the code at commit 1ba2d27 (before PRs #12-#15), so
    /// this opens a genuine old on-disk store with today's schema.
    func testStoreWrittenBeforeFuelAndMediaMigratesWithItsData() throws {
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "legacy-pre-fuel", withExtension: "store"))
        let storeURL = dir.appending(path: "legacy.store")
        try FileManager.default.copyItem(at: fixture, to: storeURL)

        let container = Persistence.open(ModelConfiguration(url: storeURL))
        let context = container.mainContext

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(exercises.map(\.name), ["Legacy Squat"])
        let legacy = try XCTUnwrap(exercises.first)
        XCTAssertEqual(legacy.sectionRaw, "gym", "new defaulted column must backfill")
        XCTAssertTrue(legacy.media.isEmpty)
        XCTAssertEqual(legacy.personalNotes, "")
        XCTAssertEqual(legacy.progressionRuleRaw, "", "a row written before rules existed keeps the automatic one")
        XCTAssertNil(legacy.progressionStepKg)
        let sets = try context.fetch(FetchDescriptor<SetEntry>(sortBy: [SortDescriptor(\.order)]))
        XCTAssertEqual(sets.map(\.weightKg), [100, 102.5, 105])
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Routine>()), 1)
        XCTAssertTrue(try context.fetch(FetchDescriptor<WorkoutExercise>()).allSatisfy { $0.supersetGroup == nil })
        XCTAssertTrue(try context.fetch(FetchDescriptor<RoutineExercise>()).allSatisfy { $0.supersetGroup == nil })
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<FoodEntry>()), 0)

        let leftovers = try FileManager.default.contentsOfDirectory(atPath: dir.path(percentEncoded: false))
        XCTAssertFalse(leftovers.contains { $0.contains(".corrupt-") }, "migration must not fall back to quarantine: \(leftovers)")
    }
}
