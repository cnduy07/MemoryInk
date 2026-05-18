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

        try writeJPEG(image, to: url(forRelativePath: originalPath), quality: 0.92)
        try writeJPEG(resized(image, maxPixelDimension: 500), to: url(forRelativePath: thumbnailPath), quality: 0.82)
        try writeJPEG(resized(image, maxPixelDimension: 1600), to: url(forRelativePath: mediumPreviewPath), quality: 0.86)

        return StoredImageSet(
            originalPath: originalPath,
            thumbnailPath: thumbnailPath,
            mediumPreviewPath: mediumPreviewPath
        )
    }

    func image(forRelativePath path: String) -> UIImage? {
        UIImage(contentsOfFile: url(forRelativePath: path).path)
    }

    func url(forRelativePath path: String) -> URL {
        documentsURL.appendingPathComponent(path)
    }

    static func image(forRelativePath path: String) -> UIImage? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return UIImage(contentsOfFile: documentsURL.appendingPathComponent(path).path)
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

    private func resized(_ image: UIImage, maxPixelDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)

        guard longestSide > maxPixelDimension else {
            return image
        }

        let scale = maxPixelDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
