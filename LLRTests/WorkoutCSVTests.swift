import XCTest
@testable import LLR

final class WorkoutCSVTests: XCTestCase {
    private let hevyHeader = #""title","start_time","end_time","description","exercise_title","superset_id","exercise_notes","set_index","set_type","weight_kg","reps","distance_km","duration_seconds","rpe""#

    private func hevy(_ rows: [String], header: String? = nil) -> String {
        ([header ?? hevyHeader] + rows).joined(separator: "\n")
    }

    func testHevyGroupsSetsAndMapsSetTypes() throws {
        let text = hevy([
            #""Push Day","28 Mar 2025, 17:29","28 Mar 2025, 18:52","Felt strong","Bench Press (Barbell)",,"",0,"warmup",40,10,,,"#,
            #""Push Day","28 Mar 2025, 17:29","28 Mar 2025, 18:52","Felt strong","Bench Press (Barbell)",,"",1,"normal",80,8,,,8"#,
            #""Push Day","28 Mar 2025, 17:29","28 Mar 2025, 18:52","Felt strong","Bench Press (Barbell)",,"",2,"dropset",60,12,,,"#,
            #""Push Day","28 Mar 2025, 17:29","28 Mar 2025, 18:52","Felt strong","Treadmill",,"",0,"normal",,,1.2,600,"#,
            #""Push Day","28 Mar 2025, 17:29","28 Mar 2025, 18:52","Felt strong","Push Up",,"",0,"failure",,25,,,"#,
        ])
        let parsed = try WorkoutCSV.parse(text, strongUnit: .kg)
        XCTAssertEqual(parsed.source, .hevy)
        XCTAssertEqual(parsed.skippedTimedSets, 1)
        let workout = try XCTUnwrap(parsed.workouts.first)
        XCTAssertEqual(parsed.workouts.count, 1)
        XCTAssertEqual(workout.name, "Push Day")
        XCTAssertEqual(workout.notes, "Felt strong")
        XCTAssertEqual(workout.endedAt.timeIntervalSince(workout.startedAt), 83 * 60)
        XCTAssertEqual(workout.exercises.map(\.name), ["Bench Press (Barbell)", "Push Up"])
        XCTAssertEqual(workout.exercises[0].sets, [
            ImportedSet(weightKg: 40, reps: 10, kind: .warmup),
            ImportedSet(weightKg: 80, reps: 8, kind: .normal, rir: 2),
            ImportedSet(weightKg: 60, reps: 12, kind: .drop),
        ])
        XCTAssertEqual(workout.exercises[1].sets, [ImportedSet(weightKg: 0, reps: 25, kind: .failure)])
    }

    func testHevyPoundsColumnIsConverted() throws {
        let header = hevyHeader.replacingOccurrences(of: "weight_kg", with: "weight_lbs")
        let text = hevy([#""Legs","1 Apr 2025, 07:05","1 Apr 2025, 08:00","","Squat (Barbell)",,"",0,"normal",225,5,,,"#], header: header)
        let set = try XCTUnwrap(WorkoutCSV.parse(text, strongUnit: .kg).workouts.first?.exercises.first?.sets.first)
        XCTAssertEqual(set.weightKg, 225 * WeightUnit.kgPerLb, accuracy: 0.0001)
    }

    private let strongHeader = "Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE"

    func testStrongSetTagsDurationAndSkippedRows() throws {
        let text = [
            strongHeader,
            #"2020-12-30 18:51:52,"Evening Workout",1h 5m,"Squat (Barbell)",W,60.0,5,0,0,"","Heavy day","#,
            #"2020-12-30 18:51:52,"Evening Workout",1h 5m,"Squat (Barbell)",1,100.0,5,0,0,,,"#,
            #"2020-12-30 18:51:52,"Evening Workout",1h 5m,"Squat (Barbell)",F,100.0,3,0,0,,,"#,
            #"2020-12-30 18:51:52,"Evening Workout",1h 5m,"Squat (Barbell)",Rest Timer,0,0,0,90,,,"#,
            #"2020-12-30 18:51:52,"Evening Workout",1h 5m,"Plank",1,0,0,0,60,,,"#,
            #"2021-01-02 09:00:00,"Morning",45m,"Clean (Barbell)",1,70.0,2,0,0,,,"#,
        ].joined(separator: "\n")
        let parsed = try WorkoutCSV.parse(text, strongUnit: .kg)
        XCTAssertEqual(parsed.source, .strong)
        XCTAssertEqual(parsed.workouts.map(\.name), ["Evening Workout", "Morning"])
        XCTAssertEqual(parsed.skippedTimedSets, 1, "the Plank row; the Rest Timer row is not a set at all")
        let evening = parsed.workouts[0]
        XCTAssertEqual(evening.notes, "Heavy day")
        XCTAssertEqual(evening.endedAt.timeIntervalSince(evening.startedAt), 65 * 60)
        XCTAssertEqual(evening.exercises.first?.sets.map(\.kind), [.warmup, .normal, .failure])
    }

    func testStrongHeldRepBecomesADurationSet() throws {
        let text = [
            strongHeader,
            #"2020-12-30 18:51:52,"Back Care",20m,"Bird Dog",1,0,5,0,15,,,"#,
        ].joined(separator: "\n")
        let set = try XCTUnwrap(WorkoutCSV.parse(text, strongUnit: .kg).workouts.first?.exercises.first?.sets.first)
        XCTAssertEqual(set, ImportedSet(weightKg: 0, reps: 5, kind: .normal, durationSeconds: 15))
    }

    func testStrongSemicolonFileWithCommaDecimalsInPounds() throws {
        let text = """
        Date;Workout Name;Duration;Exercise Name;Set Order;Weight;Reps;Distance;Seconds;Notes;Workout Notes;RPE
        2021-03-01 10:00:00;"Upper";50m;"Bench Press (Barbell)";1;"135,5";8;0;0;;;
        """
        let set = try XCTUnwrap(WorkoutCSV.parse(text, strongUnit: .lbs).workouts.first?.exercises.first?.sets.first)
        XCTAssertEqual(set.weightKg, 135.5 * WeightUnit.kgPerLb, accuracy: 0.0001)
        XCTAssertEqual(set.reps, 8)
    }

    func testForeignCSVIsRejected() {
        XCTAssertThrowsError(try WorkoutCSV.parse("name,price\nshoe,10\n", strongUnit: .kg))
        XCTAssertThrowsError(try WorkoutCSV.parse("", strongUnit: .kg))
    }

    func testDurationTextBothWays() {
        XCTAssertEqual(WorkoutCSV.duration("2h 38m"), 158 * 60)
        XCTAssertEqual(WorkoutCSV.duration("45m"), 45 * 60)
        XCTAssertEqual(WorkoutCSV.duration("30s"), 30)
        XCTAssertEqual(WorkoutExport.durationText(65 * 60), "1h 5m")
        XCTAssertEqual(WorkoutExport.durationText(45 * 60), "45m")
    }

    func testMatcherExactThenSameEquipmentOnly() {
        let candidates = [
            ExerciseMatcher.Candidate(name: "Clean", equipment: ["Barbell"]),
            ExerciseMatcher.Candidate(name: "Push Up", equipment: []),
            ExerciseMatcher.Candidate(name: "Bench Press (Barbell)", equipment: ["Barbell"]),
        ]
        XCTAssertEqual(ExerciseMatcher.match("bench press (barbell)", in: candidates), 2)
        XCTAssertEqual(ExerciseMatcher.match("Clean (Barbell)", in: candidates), 0)
        XCTAssertNil(ExerciseMatcher.match("Clean (Dumbbell)", in: candidates))
        XCTAssertNil(ExerciseMatcher.match("Push Up (Weighted)", in: candidates))
        XCTAssertNil(ExerciseMatcher.match("Snatch Ballance", in: candidates))
    }

    func testCorruptNumbersAreSkippedNotCrashed() throws {
        let text = [
            strongHeader,
            #"2021-01-02 09:00:00,"Morning",infh,"Squat (Barbell)",1,inf,nan,0,0,,,"#,
            #"2021-01-02 09:00:00,"Morning",infh,"Squat (Barbell)",2,100,1e30,0,0,,,"#,
            #"2021-01-02 09:00:00,"Morning",infh,"Squat (Barbell)",3,1e300,5,0,99999999999,,,"#,
        ].joined(separator: "\n")
        let parsed = try WorkoutCSV.parse(text, strongUnit: .kg)
        XCTAssertEqual(parsed.skippedTimedSets, 2, "reps of nan and 1e30 are no reps")
        let workout = try XCTUnwrap(parsed.workouts.first)
        XCTAssertEqual(workout.endedAt, workout.startedAt, "an infinite duration is ignored")
        let set = try XCTUnwrap(workout.exercises.first?.sets.first)
        XCTAssertEqual(set.weightKg, 0, "an impossible weight reads as none")
        XCTAssertEqual(set.reps, 5)
        XCTAssertNil(set.durationSeconds, "a hold longer than a day is not a hold")
    }

    func testDurationIsCappedAndIgnoresNonsenseTokens() {
        XCTAssertEqual(WorkoutCSV.duration("1e300h"), WorkoutCSV.maxDuration)
        XCTAssertEqual(WorkoutCSV.duration("nanm 30s"), 30)
        XCTAssertEqual(WorkoutCSV.duration("-5m 30s"), 30)
    }

    func testHevyRepsBeyondTheLimitAreSkipped() throws {
        let text = hevy([
            #""Legs","1 Apr 2025, 07:05","1 Apr 2025, 08:00","","Squat (Barbell)",,"",0,"normal",100,9000000000000000000,,,"#,
            #""Legs","1 Apr 2025, 07:05","1 Apr 2025, 08:00","","Squat (Barbell)",,"",1,"normal",100,5.0,,,"#,
        ])
        let parsed = try WorkoutCSV.parse(text, strongUnit: .kg)
        XCTAssertEqual(parsed.skippedTimedSets, 1)
        XCTAssertEqual(parsed.workouts.first?.exercises.first?.sets.map(\.reps), [5])
    }
}
