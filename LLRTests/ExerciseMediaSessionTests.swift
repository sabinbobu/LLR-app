import XCTest
@testable import LLR

final class ExerciseMediaSessionTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func write(_ name: String) throws -> ExerciseMediaItem {
        try Data("x".utf8).write(to: ExerciseMediaStore.url(for: name, root: root))
        return ExerciseMediaItem(kind: .photo, fileName: name)
    }

    private func exists(_ item: ExerciseMediaItem) -> Bool {
        FileManager.default.fileExists(atPath: ExerciseMediaStore.url(for: item.fileName, root: root).path())
    }

    func testCommitDeletesFilesAddedThenRemovedButKeepsTheRest() throws {
        let session = ExerciseMediaSession(root: root)
        let kept = try write("kept.jpg")
        let dropped = try write("dropped.jpg")
        session.record(kept)
        session.record(dropped)

        session.commit(keeping: [kept])

        XCTAssertTrue(exists(kept))
        XCTAssertFalse(exists(dropped))
    }

    func testCancelDeletesEverythingWrittenThisSession() throws {
        let session = ExerciseMediaSession(root: root)
        let a = try write("a.jpg")
        let b = try write("b.jpg")
        session.record(a)
        session.record(b)

        session.cancel()

        XCTAssertFalse(exists(a))
        XCTAssertFalse(exists(b))
    }

    func testImportFinishingAfterCloseDeletesItsOwnFile() throws {
        let session = ExerciseMediaSession(root: root)
        session.cancel()
        let late = try write("late.jpg")

        session.record(late)

        XCTAssertFalse(exists(late))
    }

    func testCancelAfterCommitDoesNotDeleteSavedFiles() throws {
        let session = ExerciseMediaSession(root: root)
        let saved = try write("saved.jpg")
        session.record(saved)
        session.commit(keeping: [saved])

        session.cancel()

        XCTAssertTrue(exists(saved))
    }
}
