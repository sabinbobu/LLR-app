import XCTest
@testable import LLR

final class ExerciseLibraryTests: XCTestCase {
    func testParsesNameAndMuscleFields() throws {
        let json = """
        [{"Name": "Bench Press (Barbell)", "Muscle": "Chest"}, {"Name": "Squat (Barbell)", "Muscle": "Quadriceps"}]
        """.data(using: .utf8)!
        let seeds = try ExerciseLibrary.parseSeeds(json)
        XCTAssertEqual(seeds.map(\.name), ["Bench Press (Barbell)", "Squat (Barbell)"])
        XCTAssertEqual(seeds.map(\.muscle), ["Chest", "Quadriceps"])
    }

    func testEmptyArrayParsesToEmpty() throws {
        XCTAssertTrue(try ExerciseLibrary.parseSeeds("[]".data(using: .utf8)!).isEmpty)
    }

    func testMalformedJSONThrows() {
        XCTAssertThrowsError(try ExerciseLibrary.parseSeeds("not json".data(using: .utf8)!))
    }
}
