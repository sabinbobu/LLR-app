import UIKit

/// The avatar is one small file rather than a SwiftData model: it's a setting, not history,
/// and a file avoids a schema change for a single optional image.
enum AvatarStore {
    private static var url: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("avatar.jpg")
    }

    static func load() -> UIImage? {
        url.flatMap { try? Data(contentsOf: $0) }.flatMap(UIImage.init(data:))
    }

    static func save(_ data: Data) {
        guard let url, let jpeg = ImageDownscale.jpeg(data, maxDimension: 512) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? jpeg.write(to: url, options: .atomic)
    }

    static func delete() {
        if let url { try? FileManager.default.removeItem(at: url) }
    }
}
