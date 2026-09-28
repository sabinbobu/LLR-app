import SwiftData
import UIKit
import XCTest
@testable import LLR

final class CustomExerciseTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Exercise.self, Workout.self, WorkoutExercise.self, SetEntry.self, ExerciseMedia.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func testNameMustBeNonEmptyAndUniqueIgnoringCase() {
        var draft = CustomExerciseDraft(section: .gym, name: "   ")
        XCTAssertEqual(draft.problem(existingNames: []), .emptyName)
        draft.name = "bench press"
        XCTAssertEqual(draft.problem(existingNames: ["Bench Press"]), .duplicateName)
        // Keeping its own name while editing isn't a clash.
        XCTAssertNil(draft.problem(existingNames: ["Bench Press"], originalName: "Bench Press"))
        draft.name = "Landmine Press"
        XCTAssertNil(draft.problem(existingNames: ["Bench Press"]))
    }

    func testGymDraftRoundTripsEveryField() throws {
        let context = try makeContext()
        var draft = CustomExerciseDraft(section: .gym, name: "  Landmine Press ")
        draft.muscleGroup = MuscleGroup.shoulders.rawValue
        draft.secondaryMuscles = [MuscleGroup.triceps.rawValue, MuscleGroup.shoulders.rawValue]
        draft.equipment = ["Barbell", "Plate"]
        draft.instructions = ["Brace", " ", "Press up and forward"]
        draft.restSeconds = 90
        draft.repRange = 8...12

        let exercise = Exercise(name: draft.trimmedName, muscleGroup: draft.muscleGroup, isCustom: true)
        context.insert(exercise)
        draft.apply(to: exercise)

        XCTAssertEqual(exercise.name, "Landmine Press")
        XCTAssertEqual(exercise.sectionRaw, "gym")
        XCTAssertEqual(exercise.secondaryMuscles, [MuscleGroup.triceps.rawValue], "primary is not also secondary")
        XCTAssertEqual(exercise.equipment, ["Barbell", "Plate"])
        XCTAssertEqual(exercise.instructions, ["Brace", "Press up and forward"], "blank steps are dropped")
        XCTAssertEqual(exercise.restSeconds, 90)
        XCTAssertEqual(exercise.repRange, 8...12)

        let reopened = CustomExerciseDraft(exercise)
        XCTAssertEqual(reopened.name, "Landmine Press")
        XCTAssertEqual(reopened.equipment, ["Barbell", "Plate"])
        XCTAssertEqual(reopened.repRange, 8...12)
        XCTAssertEqual(reopened.restSeconds, 90)
    }

    func testKinetoDraftBecomesACatalogShapedSpec() throws {
        let context = try makeContext()
        var draft = CustomExerciseDraft(section: .kineto, name: "Wall Slide")
        draft.kinetoCategory = .nerveMobility
        draft.kinetoDirection = .extension
        draft.kinetoLevels = [
            KinetoCatalog.Level(label: " L1 — Short ", sets: 2, reps: nil, durationSeconds: 20, notes: "  "),
            KinetoCatalog.Level(label: "  ", sets: 3, reps: 0, durationSeconds: 30, notes: "Each side"),
        ]
        draft.kinetoMistakes = "Arching"
        draft.kinetoCautions = "  "
        draft.instructions = ["Stand tall"]

        let exercise = Exercise(name: draft.trimmedName, muscleGroup: draft.muscleGroup, isCustom: true)
        context.insert(exercise)
        draft.apply(to: exercise)

        let spec = try XCTUnwrap(exercise.customKinetoSpec)
        XCTAssertEqual(spec.category, .nerveMobility)
        XCTAssertEqual(spec.direction, .extension)
        XCTAssertEqual(spec.levels.map(\.label), ["L1 — Short", "Level 2"], "trimmed, and a blank label gets its position")
        XCTAssertEqual(spec.levels.map(\.doseText), ["2 × 20 s", "3 × 30 s"], "a zero count means it doesn't apply")
        XCTAssertNil(spec.levels[0].notes)
        XCTAssertEqual(spec.levels[1].notes, "Each side")
        XCTAssertEqual(spec.mistakes, "Arching")
        XCTAssertNil(spec.cautions, "blank notes are not shown as an empty card")
        XCTAssertEqual(spec.howto, ["Stand tall"])
        XCTAssertTrue(spec.sources.isEmpty)
        XCTAssertFalse(spec.prescribedOnly)
        XCTAssertEqual(CustomExerciseDraft(exercise).kinetoLevels, spec.levels)
    }

    func testKinetoDraftRoundTripsSourcesAndSharedFields() throws {
        let context = try makeContext()
        var draft = CustomExerciseDraft(section: .kineto, name: "Wall Slide")
        draft.secondaryMuscles = [MuscleGroup.glutes.rawValue, MuscleGroup.abdominals.rawValue]
        draft.equipment = ["Resistance Band"]
        draft.restSeconds = 45
        draft.kinetoSources = [
            KinetoCatalog.Source(title: " Ana Pop ", url: nil, kind: KinetoCatalog.SourceKind.physiotherapist.rawValue),
            KinetoCatalog.Source(title: "", url: "https://example.org/leaflet", kind: "patient-education"),
            KinetoCatalog.Source(title: " ", url: " ", kind: "other"),
        ]

        let exercise = Exercise(name: draft.trimmedName, muscleGroup: draft.muscleGroup, isCustom: true)
        context.insert(exercise)
        draft.apply(to: exercise)

        XCTAssertEqual(exercise.secondaryMuscles, [MuscleGroup.glutes.rawValue], "primary is not also secondary")
        XCTAssertEqual(exercise.equipment, ["Resistance Band"])
        XCTAssertEqual(exercise.restSeconds, 45)
        let sources = try XCTUnwrap(exercise.customKinetoSpec?.sources)
        XCTAssertEqual(sources.map(\.title), ["Ana Pop", "https://example.org/leaflet"], "blank sources are dropped")
        XCTAssertTrue(sources[0].isPrescription)
        XCTAssertNil(sources[0].link)
        XCTAssertEqual(sources[1].link, URL(string: "https://example.org/leaflet"))

        let reopened = CustomExerciseDraft(exercise)
        XCTAssertEqual(reopened.kinetoSources, sources)
        XCTAssertEqual(reopened.equipment, ["Resistance Band"])
        XCTAssertEqual(reopened.restSeconds, 45)
    }

    func testARowFromBeforeLevelsReadsItsSingleDoseAsOneLevel() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Wall Slide", muscleGroup: "Abdominals", isCustom: true)
        context.insert(exercise)
        exercise.sectionRaw = WorkoutSection.kineto.rawValue
        exercise.kinetoSets = 3
        exercise.kinetoReps = 10
        exercise.kinetoDurationSeconds = 5

        XCTAssertEqual(exercise.customKinetoSpec?.levels.map(\.doseText), ["3 × 10 × 5 s"])

        // Saving from the editor moves it to levels and clears the old dose.
        CustomExerciseDraft(exercise).apply(to: exercise)
        XCTAssertNotNil(exercise.kinetoLevelsData)
        XCTAssertNil(exercise.kinetoSets)
        XCTAssertEqual(exercise.customKinetoSpec?.levels.map(\.doseText), ["3 × 10 × 5 s"])
    }

    func testKinetoDraftNeedsALevelAndHttpsSourceLinks() {
        var draft = CustomExerciseDraft(section: .kineto, name: "Wall Slide")
        XCTAssertNil(draft.problem(existingNames: []))
        draft.kinetoLevels = []
        XCTAssertEqual(draft.problem(existingNames: []), .noLevels)
        draft.kinetoLevels = [KinetoCatalog.Level(label: "L1", sets: 1, reps: 5, durationSeconds: nil, notes: nil)]

        for bad in ["http://example.org", "example.org", "https://"] {
            draft.kinetoSources = [KinetoCatalog.Source(title: "Leaflet", url: bad, kind: "other")]
            XCTAssertEqual(draft.problem(existingNames: []), .invalidSourceURL, bad)
        }
        draft.kinetoSources = [KinetoCatalog.Source(title: "Ana Pop", url: nil, kind: "physiotherapist")]
        XCTAssertNil(draft.problem(existingNames: []), "a prescription needs no link")

        // Gym exercises carry no levels or sources, so neither can block their save.
        var gym = CustomExerciseDraft(section: .gym, name: "Landmine Press")
        gym.kinetoLevels = []
        XCTAssertNil(gym.problem(existingNames: []))
    }

    func testSectionKeepsCustomKinetoOutOfGymQueries() throws {
        let context = try makeContext()
        let gym = Exercise(name: "Landmine Press", muscleGroup: "Shoulders", isCustom: true)
        let kineto = Exercise(name: "Wall Slide", muscleGroup: "Abdominals", isCustom: true)
        context.insert(gym)
        context.insert(kineto)
        CustomExerciseDraft(section: .kineto, name: "Wall Slide").apply(to: kineto)

        let gymRows = try context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.sectionRaw == "gym" }))
        let kinetoRows = try context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.isCustom && $0.sectionRaw == "kineto" }))
        XCTAssertEqual(gymRows.map(\.name), ["Landmine Press"])
        XCTAssertEqual(kinetoRows.map(\.name), ["Wall Slide"])
        XCTAssertNil(gym.customKinetoSpec)
    }

    func testDeletingAnUnusedExerciseRemovesItsMediaRowsAndFiles() throws {
        let context = try makeContext()
        let photo = try ExerciseMediaStore.savePhoto(Self.pngData())
        let exercise = Exercise(name: "Landmine Press", muscleGroup: "Shoulders", isCustom: true)
        context.insert(exercise)
        let row = ExerciseMedia(kind: photo.kind, fileName: photo.fileName)
        context.insert(row)
        row.exercise = exercise
        try context.save()
        XCTAssertTrue(exercise.canDelete)

        exercise.deleteWithMedia(from: context)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<ExerciseMedia>()).isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: ExerciseMediaStore.url(for: photo.fileName).path()))
    }

    func testALoggedExerciseCannotBeDeleted() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Landmine Press", muscleGroup: "Shoulders", isCustom: true)
        let entry = WorkoutExercise(order: 0)
        context.insert(exercise)
        context.insert(entry)
        entry.exercise = exercise
        XCTAssertFalse(exercise.canDelete)
    }

    func testPhotoIsDownscaledToAJPEGOnDisk() throws {
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let item = try ExerciseMediaStore.savePhoto(Self.pngData(size: 3000), root: root)

        XCTAssertEqual(item.kind, .photo)
        XCTAssertTrue(item.fileName.hasSuffix(".jpg"))
        let image = try XCTUnwrap(UIImage(contentsOfFile: ExerciseMediaStore.url(for: item.fileName, root: root).path()))
        XCTAssertEqual(max(image.size.width, image.size.height), 2048, accuracy: 1)

        ExerciseMediaStore.delete(item.fileName, root: root)
        XCTAssertFalse(FileManager.default.fileExists(atPath: ExerciseMediaStore.url(for: item.fileName, root: root).path()))
    }

    private static func pngData(size: CGFloat = 10) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
}
