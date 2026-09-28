import AVFoundation
import CoreTransferable
import UIKit
import UniformTypeIdentifiers

/// Files behind `ExerciseMedia` rows. Photos are downscaled and videos re-encoded to 720p on the
/// way in: everything stays on the phone, and a minute of 4K is ~350 MB against ~30 MB at 720p.
enum ExerciseMediaStore {
    enum StoreError: Error {
        case unreadableImage, exportFailed
    }

    static let defaultRoot: URL = URL.applicationSupportDirectory.appending(path: "ExerciseMedia", directoryHint: .isDirectory)

    static func url(for fileName: String, root: URL = defaultRoot) -> URL {
        root.appending(path: fileName, directoryHint: .notDirectory)
    }

    static func savePhoto(_ data: Data, root: URL = defaultRoot) throws -> ExerciseMediaItem {
        guard let jpeg = ImageDownscale.jpeg(data, maxDimension: 2048) else { throw StoreError.unreadableImage }
        return try savePhotoJPEG(jpeg, root: root)
    }

    static func savePhoto(_ image: UIImage, root: URL = defaultRoot) throws -> ExerciseMediaItem {
        guard let jpeg = ImageDownscale.jpeg(image, maxDimension: 2048) else { throw StoreError.unreadableImage }
        return try savePhotoJPEG(jpeg, root: root)
    }

    private static func savePhotoJPEG(_ jpeg: Data, root: URL) throws -> ExerciseMediaItem {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let item = ExerciseMediaItem(kind: .photo, fileName: "\(UUID().uuidString).jpg")
        try jpeg.write(to: url(for: item.fileName, root: root), options: .atomic)
        return item
    }

    /// Re-encodes `source` to 720p MP4 and removes `source`, which is always a temporary copy.
    static func saveVideo(from source: URL, root: URL = defaultRoot) async throws -> ExerciseMediaItem {
        defer { try? FileManager.default.removeItem(at: source) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let item = ExerciseMediaItem(kind: .video, fileName: "\(UUID().uuidString).mp4")
        let destination = url(for: item.fileName, root: root)
        guard let session = AVAssetExportSession(asset: AVURLAsset(url: source), presetName: AVAssetExportPreset1280x720) else {
            throw StoreError.exportFailed
        }
        if #available(iOS 18, *) {
            try await session.export(to: destination, as: .mp4)
        } else {
            session.outputURL = destination
            session.outputFileType = .mp4
            await session.export()
            guard session.status == .completed else { throw session.error ?? StoreError.exportFailed }
        }
        return item
    }

    static func delete(_ fileName: String, root: URL = defaultRoot) {
        try? FileManager.default.removeItem(at: url(for: fileName, root: root))
    }

    static func thumbnail(for item: ExerciseMediaItem, maxDimension: CGFloat = 400) async -> UIImage? {
        let fileURL = url(for: item.fileName)
        switch item.kind {
        case .photo:
            return await UIImage(contentsOfFile: fileURL.path())?
                .byPreparingThumbnail(ofSize: CGSize(width: maxDimension, height: maxDimension))
        case .video:
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: fileURL))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: maxDimension, height: maxDimension)
            guard let (image, _) = try? await generator.image(at: .zero) else { return nil }
            return UIImage(cgImage: image)
        }
    }
}

/// A picked video, copied out of the picker's short-lived file so it survives until it's re-encoded.
struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { SentTransferredFile($0.url) } importing: { received in
            let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(received.file.pathExtension)")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return PickedVideo(url: copy)
        }
    }
}
