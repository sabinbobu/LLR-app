import Foundation
import SwiftData

enum ExerciseMediaKind: String {
    case photo, video
}

/// A personal photo or video attached to an exercise. The bytes live in a file (see
/// `ExerciseMediaStore`), not the store: a player needs a file URL, and a video loaded as `Data`
/// would sit entirely in memory.
@Model
final class ExerciseMedia {
    var id: UUID
    var kindRaw: String
    var fileName: String
    var createdAt: Date
    var exercise: Exercise?

    init(kind: ExerciseMediaKind, fileName: String, createdAt: Date = .now) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.fileName = fileName
        self.createdAt = createdAt
    }
}

extension ExerciseMedia {
    var kind: ExerciseMediaKind { ExerciseMediaKind(rawValue: kindRaw) ?? .photo }
    var item: ExerciseMediaItem { ExerciseMediaItem(kind: kind, fileName: fileName) }
}

extension Exercise {
    var mediaItems: [ExerciseMediaItem] { media.sorted { $0.createdAt < $1.createdAt }.map(\.item) }

    /// Makes `media` match `items`, which an editor built up: dropped rows lose their files too, but
    /// only once the change is saved, so a failed save can't leave rows pointing at deleted files.
    func syncMedia(to items: [ExerciseMediaItem], in context: ModelContext) {
        let wanted = Set(items.map(\.fileName))
        var droppedFiles: [String] = []
        for row in media where !wanted.contains(row.fileName) {
            droppedFiles.append(row.fileName)
            context.delete(row)
        }
        let existing = Set(media.map(\.fileName))
        // Staggered timestamps keep the order the user added them in.
        for (index, item) in items.enumerated() where !existing.contains(item.fileName) {
            let row = ExerciseMedia(kind: item.kind, fileName: item.fileName, createdAt: .now.addingTimeInterval(Double(index) / 1000))
            context.insert(row)
            row.exercise = self
        }
        if (try? context.save()) != nil {
            for file in droppedFiles { ExerciseMediaStore.delete(file) }
        }
    }
}

/// Every file an editor wrote this session. An item can be added and removed again before Save, so
/// the draft alone can't say which files are garbage; this ledger can. Once closed, a late-finishing
/// import (the editor dismissed mid-copy) deletes its own file instead of leaking it.
final class ExerciseMediaSession {
    private let root: URL
    private var written: [ExerciseMediaItem] = []
    private var closed = false

    init(root: URL = ExerciseMediaStore.defaultRoot) { self.root = root }

    var hasWritten: Bool { !written.isEmpty }

    func record(_ item: ExerciseMediaItem) {
        if closed {
            ExerciseMediaStore.delete(item.fileName, root: root)
        } else {
            written.append(item)
        }
    }

    /// Cancel: nothing written this session will ever be referenced.
    func cancel() { close(keeping: []) }

    /// Save: keep what the draft still holds, drop the rest.
    func commit(keeping items: [ExerciseMediaItem]) { close(keeping: items) }

    private func close(keeping items: [ExerciseMediaItem]) {
        guard !closed else { return }
        closed = true
        let keep = Set(items)
        for item in written where !keep.contains(item) { ExerciseMediaStore.delete(item.fileName, root: root) }
    }
}

/// A value copy of one attachment, so editors can add and remove media before anything is saved.
struct ExerciseMediaItem: Hashable, Identifiable {
    let kind: ExerciseMediaKind
    let fileName: String

    var id: String { fileName }
}
