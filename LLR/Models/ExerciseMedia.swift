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

    /// Makes `media` match `items`, which an editor built up: dropped rows lose their files too.
    func syncMedia(to items: [ExerciseMediaItem], in context: ModelContext) {
        let wanted = Set(items.map(\.fileName))
        for row in media where !wanted.contains(row.fileName) {
            ExerciseMediaStore.delete(row.fileName)
            context.delete(row)
        }
        let existing = Set(media.map(\.fileName))
        // Staggered timestamps keep the order the user added them in.
        for (index, item) in items.enumerated() where !existing.contains(item.fileName) {
            let row = ExerciseMedia(kind: item.kind, fileName: item.fileName, createdAt: .now.addingTimeInterval(Double(index) / 1000))
            context.insert(row)
            row.exercise = self
        }
    }
}

extension ExerciseMediaStore {
    /// On Cancel: files an editor wrote for items added this session, which nothing will reference.
    static func discard(_ items: [ExerciseMediaItem], keeping kept: [ExerciseMediaItem]) {
        let keep = Set(kept)
        for item in items where !keep.contains(item) { delete(item.fileName) }
    }
}

/// A value copy of one attachment, so editors can add and remove media before anything is saved.
struct ExerciseMediaItem: Hashable, Identifiable {
    let kind: ExerciseMediaKind
    let fileName: String

    var id: String { fileName }
}
