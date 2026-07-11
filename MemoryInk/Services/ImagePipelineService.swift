import Combine
import UIKit

struct StoredImageSet {
    let originalPath: String
    let thumbnailPath: String
    let mediumPreviewPath: String
}

final class ImagePipelineService: ObservableObject {
    enum ImagePipelineError: Error {
        case invalidImageData
        case jpegEncodingFailed
    }

    private static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 120
        cache.totalCostLimit = 64 * 1_024 * 1_024
        return cache
    }()

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        createStorageDirectoriesIfNeeded()
    }

    func saveImage(_ image: UIImage, id: UUID) throws -> StoredImageSet {
        createStorageDirectoriesIfNeeded()

        let originalPath = "originals/\(id.uuidString).jpg"
        let thumbnailPath = "thumbnails/\(id.uuidString).jpg"
        let mediumPreviewPath = "medium/\(id.uuidString).jpg"

        let thumbnail = resized(image, maxPixelDimension: 500)
        let mediumPreview = resized(image, maxPixelDimension: 1600)

        try writeJPEG(image, to: url(forRelativePath: originalPath), quality: 0.92)
        try writeJPEG(thumbnail, to: url(forRelativePath: thumbnailPath), quality: 0.82)
        try writeJPEG(mediumPreview, to: url(forRelativePath: mediumPreviewPath), quality: 0.86)

        Self.cache(thumbnail, for: url(forRelativePath: thumbnailPath))
        Self.cache(mediumPreview, for: url(forRelativePath: mediumPreviewPath))

        return StoredImageSet(
            originalPath: originalPath,
            thumbnailPath: thumbnailPath,
            mediumPreviewPath: mediumPreviewPath
        )
    }

    func image(forRelativePath path: String) -> UIImage? {
        Self.cachedImage(at: url(forRelativePath: path))
    }

    func preparedImage(forRelativePath path: String) async -> UIImage? {
        let imageURL = url(forRelativePath: path)

        if let cachedImage = Self.imageCache.object(forKey: imageURL.path as NSString) {
            return cachedImage
        }

        guard let image = UIImage(contentsOfFile: imageURL.path) else {
            return nil
        }

        let preparedImage = await image.byPreparingForDisplay() ?? image
        Self.cache(preparedImage, for: imageURL)
        return preparedImage
    }

    func url(forRelativePath path: String) -> URL {
        documentsURL.appendingPathComponent(path)
    }

    static func image(forRelativePath path: String) -> UIImage? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return cachedImage(at: documentsURL.appendingPathComponent(path))
    }

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func createStorageDirectoriesIfNeeded() {
        ["originals", "thumbnails", "medium", "voice"].forEach { directory in
            let url = documentsURL.appendingPathComponent(directory, isDirectory: true)
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func writeJPEG(_ image: UIImage, to url: URL, quality: CGFloat) throws {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw ImagePipelineError.jpegEncodingFailed
        }

        try data.write(to: url, options: [.atomic])
    }

    private static func cachedImage(at url: URL) -> UIImage? {
        let key = url.path as NSString
        if let cachedImage = imageCache.object(forKey: key) {
            return cachedImage
        }

        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        cache(image, for: url)
        return image
    }

    private static func cache(_ image: UIImage, for url: URL) {
        let pixelCost: Int
        if let cgImage = image.cgImage {
            pixelCost = cgImage.bytesPerRow * cgImage.height
        } else {
            let pixelWidth = image.size.width * image.scale
            let pixelHeight = image.size.height * image.scale
            pixelCost = Int(pixelWidth * pixelHeight * 4)
        }

        imageCache.setObject(
            image,
            forKey: url.path as NSString,
            cost: max(pixelCost, 1)
        )
    }

    private func resized(_ image: UIImage, maxPixelDimension: CGFloat) -> UIImage {
        let size = image.size

        guard size.width.isFinite,
              size.height.isFinite,
              size.width > 0,
              size.height > 0,
              maxPixelDimension.isFinite,
              maxPixelDimension > 0 else {
            return image
        }

        let longestSide = max(size.width, size.height)

        guard longestSide.isFinite, longestSide > maxPixelDimension else {
            return image
        }

        let scale = maxPixelDimension / longestSide
        guard scale.isFinite, scale > 0 else {
            return image
        }

        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        guard targetSize.width.isFinite,
              targetSize.height.isFinite,
              targetSize.width > 0,
              targetSize.height > 0 else {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
