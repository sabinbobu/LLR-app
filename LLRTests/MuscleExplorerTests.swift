import XCTest
@testable import LLR

final class MuscleExplorerTests: XCTestCase {
    private struct Stub: MuscleTargeting {
        let name: String
        let muscleGroup: String
        var secondaryMuscles: [String] = []
        var equipment: [String] = []
        var isFavourite = false
    }

    private let library = [
        Stub(name: "Bench Press", muscleGroup: "Chest", secondaryMuscles: ["Triceps", "Shoulders"], equipment: ["Barbell"]),
        Stub(name: "Dip", muscleGroup: "Triceps", secondaryMuscles: ["Chest"]),
        Stub(name: "Fly", muscleGroup: "Chest", equipment: ["Dumbbell"], isFavourite: true),
        Stub(name: "Overhead Press", muscleGroup: "Shoulders", secondaryMuscles: ["Triceps"], equipment: ["Barbell"], isFavourite: true),
        Stub(name: "Push-up", muscleGroup: "Chest", secondaryMuscles: ["Triceps"]),
        Stub(name: "Rowing", muscleGroup: "Cardio", secondaryMuscles: ["Lats", "Made Up"]),
    ]

    func testMainTargetsComeBeforeAssistingOnesWithFavouritesLeadingEachHalf() {
        let hits = MuscleExplorer.hits(for: .triceps, in: library)
        XCTAssertEqual(hits.map(\.item.name), ["Dip", "Overhead Press", "Bench Press", "Push-up"])
        XCTAssertEqual(hits.map(\.isPrimary), [true, false, false, false])
        XCTAssertEqual(MuscleExplorer.hits(for: .chest, in: library).map(\.item.name), ["Fly", "Bench Press", "Push-up", "Dip"])
    }

    func testEquipmentFilterNarrowsBothHalves() {
        XCTAssertEqual(MuscleExplorer.hits(for: .triceps, in: library, equipment: "Barbell").map(\.item.name), ["Overhead Press", "Bench Press"])
        XCTAssertEqual(MuscleExplorer.hits(for: .chest, in: library, equipment: Equipment.none).map(\.item.name), ["Push-up", "Dip"])
        XCTAssertTrue(MuscleExplorer.hits(for: .calves, in: library).isEmpty)
    }

    func testCountsIncludeAssistingMusclesAndSkipWhatTheMapCannotDraw() {
        let counts = MuscleExplorer.counts(library)
        XCTAssertEqual(counts[.chest], 4)
        XCTAssertEqual(counts[.triceps], 4)
        XCTAssertEqual(counts[.shoulders], 2)
        XCTAssertEqual(counts[.lats], 1)
        XCTAssertNil(counts[.cardio])
        XCTAssertNil(counts[.calves])
        XCTAssertFalse(MuscleExplorer.muscles.contains(.cardio))
    }

    func testCountMatchesTheNumberOfHits() {
        let counts = MuscleExplorer.counts(library)
        for muscle in MuscleExplorer.muscles {
            XCTAssertEqual(counts[muscle] ?? 0, MuscleExplorer.hits(for: muscle, in: library).count, muscle.rawValue)
        }
    }

    func testSecondTapOnAMuscleClearsIt() {
        XCTAssertEqual(MuscleExplorer.selection(tapping: [.chest], current: nil), .chest)
        XCTAssertEqual(MuscleExplorer.selection(tapping: [.chest], current: .biceps), .chest)
        XCTAssertNil(MuscleExplorer.selection(tapping: [.chest], current: .chest))
    }

    func testRepeatTapsStepThroughARegionCoveringTwoMuscles() {
        let region: [MuscleGroup] = [.upperBack, .lats]
        XCTAssertEqual(MuscleExplorer.selection(tapping: region, current: nil), .upperBack)
        XCTAssertEqual(MuscleExplorer.selection(tapping: region, current: .upperBack), .lats)
        XCTAssertNil(MuscleExplorer.selection(tapping: region, current: .lats))
    }

    func testTapOnBareSpaceKeepsTheSelection() {
        XCTAssertEqual(MuscleExplorer.selection(tapping: [], current: .chest), .chest)
        XCTAssertNil(MuscleExplorer.selection(tapping: [], current: nil))
    }

    func testBodyMapPointsResolveToMuscles() {
        // Polygon centroids from body_map.json, as in BodyMapHitTestTests.
        XCTAssertEqual(MuscleExplorer.groups(at: CGPoint(x: 0.393, y: 0.249), side: .anterior), [.chest])
        XCTAssertEqual(MuscleExplorer.groups(at: CGPoint(x: 0.388, y: 0.574), side: .posterior), [.glutes])
        XCTAssertEqual(MuscleExplorer.groups(at: CGPoint(x: 0.03, y: 0.97), side: .anterior), [])
    }
}
