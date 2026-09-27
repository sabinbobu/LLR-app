import UIKit

enum ImageDownscale {
    /// JPEG re-encoded with the longest side at most `maxDimension`. Phone photos are several MB;
    /// neither the store nor a model upload needs full resolution.
    static func jpeg(_ data: Data, maxDimension: CGFloat, quality: CGFloat = 0.85) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return jpeg(image, maxDimension: maxDimension, quality: quality)
    }

    static func jpeg(_ image: UIImage, maxDimension: CGFloat, quality: CGFloat = 0.85) -> Data? {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        guard scale < 1 else { return image.jpegData(compressionQuality: quality) }
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
