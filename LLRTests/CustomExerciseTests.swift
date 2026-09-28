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
        draft.kinetoCategory = .mobility
        draft.kinetoDirection = .extension
        draft.kinetoSets = 2
        draft.kinetoReps = nil
        draft.kinetoDurationSeconds = 20
        draft.kinetoMistakes = "Arching"
        draft.kinetoCautions = "  "

        let exercise = Exercise(name: draft.trimmedName, muscleGroup: draft.muscleGroup, isCustom: true)
        context.insert(exercise)
        draft.apply(to: exercise)

        let spec = try XCTUnwrap(exercise.customKinetoSpec)
        XCTAssertEqual(spec.category, .mobility)
        XCTAssertEqual(spec.direction, .extension)
        XCTAssertEqual(spec.levels.first?.doseText, "2 × 20 s")
        XCTAssertEqual(spec.mistakes, "Arching")
        XCTAssertNil(spec.cautions, "blank notes are not shown as an empty card")
        XCTAssertTrue(spec.sources.isEmpty)
        XCTAssertEqual(CustomExerciseDraft(exercise).kinetoDurationSeconds, 20)
    }

    func testDoseTextCoversRepsHoldsAndBoth() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Bird Dog Variant", muscleGroup: "Abdominals", isCustom: true)
        context.insert(exercise)
        var draft = CustomExerciseDraft(section: .kineto, name: exercise.name)
        draft.kinetoSets = 3
        draft.kinetoReps = 10
        draft.kinetoDurationSeconds = nil
        draft.apply(to: exercise)
        XCTAssertEqual(exercise.customKinetoSpec?.levels.first?.doseText, "3 × 10")
        draft.kinetoDurationSeconds = 5
        draft.apply(to: exercise)
        XCTAssertEqual(exercise.customKinetoSpec?.levels.first?.doseText, "3 × 10 × 5 s")
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
