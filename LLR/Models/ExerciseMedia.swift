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

/// A value copy of one attachment, so editors can add and remove media before anything is saved.
struct ExerciseMediaItem: Hashable, Identifiable {
    let kind: ExerciseMediaKind
    let fileName: String

    var id: String { fileName }
}
