import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class MemoryCreationViewModel: ObservableObject {
    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed
    }

    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedCollageItems: [PhotosPickerItem] = []
    @Published var selectedImage: UIImage?
    @Published var note: String = ""
    @Published var selectedMood: MoodType = .reflective
    @Published var saveState: SaveState = .idle
    @Published var savedEntry: JournalEntry?
    @Published var isBackdropSelected: Bool = false

    /// Exposed so the post-save sheet can follow the entry as it changes — the AI narrative
    /// lands seconds *after* the save, so a snapshot taken at save time is always empty.
    let repository: JournalEntryRepository
    private let imagePipeline: ImagePipelineService
    private let narrativeGenerationService: NarrativeGenerationService
    private let analyticsService: AnalyticsService?

    init(
        repository: JournalEntryRepository,
        imagePipeline: ImagePipelineService,
        narrativeGenerationService: NarrativeGenerationService,
        analyticsService: AnalyticsService? = nil
    ) {
        self.repository = repository
        self.imagePipeline = imagePipeline
        self.narrativeGenerationService = narrativeGenerationService
        self.analyticsService = analyticsService
    }

    var canSave: Bool {
        selectedImage != nil && saveState != .saving
    }

    func loadSelectedPhoto() async {
        guard let selectedPhotoItem else { return }

        do {
            guard
                let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                saveState = .failed
                return
            }

            selectedImage = image
            isBackdropSelected = false
            saveState = .idle
        } catch {
            saveState = .failed
        }
    }

    func loadCollagePhotos() async {
        guard !selectedCollageItems.isEmpty else { return }

        var images: [UIImage] = []
        for item in selectedCollageItems {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                continue
            }

            images.append(image)
        }

        guard !images.isEmpty else { return }

        selectedImage = renderCollage(images)
        isBackdropSelected = false
        saveState = .idle
    }

    func setBackgroundScene(_ scene: BackgroundScene) {
        selectedImage = scene.render()
        isBackdropSelected = true
    }

    func save() {
        guard let selectedImage else { return }

        saveState = .saving
        let id = UUID()

        do {
            let storedImages = try imagePipeline.saveImage(selectedImage, id: id)

            let entry = try repository.createEntry(
                id: id,
                photoPath: storedImages.originalPath,
                thumbnailPath: storedImages.thumbnailPath,
                mediumPreviewPath: storedImages.mediumPreviewPath,
                rawNote: note,
                voicePath: nil,
                mood: selectedMood,
                narrativeStyle: .warm,
                syncStatus: .pending
            )

            savedEntry = entry
            saveState = .saved
            analyticsService?.track(.firstEntryCreated)

            Task {
                await narrativeGenerationService.generateNarrativeIfNeeded(for: entry)
            }
        } catch {
            saveState = .failed
        }
    }

    func saveAsSlideshow(firstImage: UIImage, videoURL: URL, mood: MoodType) {
        saveState = .saving
        let id = UUID()

        do {
            let storedImages = try imagePipeline.saveImage(firstImage, id: id)

            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let slideshowsDir = docsURL.appendingPathComponent("slideshows")
            try FileManager.default.createDirectory(at: slideshowsDir, withIntermediateDirectories: true)
            let videoFileName = "\(id.uuidString).mp4"
            let videoDestURL = slideshowsDir.appendingPathComponent(videoFileName)
            if FileManager.default.fileExists(atPath: videoDestURL.path) {
                try FileManager.default.removeItem(at: videoDestURL)
            }
            try FileManager.default.copyItem(at: videoURL, to: videoDestURL)
            let videoRelativePath = "slideshows/\(videoFileName)"

            let entry = try repository.createEntry(
                id: id,
                photoPath: storedImages.originalPath,
                thumbnailPath: storedImages.thumbnailPath,
                mediumPreviewPath: storedImages.mediumPreviewPath,
                rawNote: note.isEmpty ? nil : note,
                voicePath: videoRelativePath,
                mood: mood,
                narrativeStyle: .warm,
                syncStatus: .pending
            )

            savedEntry = entry
            saveState = .saved
            analyticsService?.track(.firstEntryCreated)

            Task {
                await narrativeGenerationService.generateNarrativeIfNeeded(for: entry)
            }
        } catch {
            saveState = .failed
        }
    }

    private func renderCollage(_ images: [UIImage]) -> UIImage {
        let canvas = CGSize(width: 1080, height: 1350)
        let gap: CGFloat = 4
        let gapColor = UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1)
        let renderer = UIGraphicsImageRenderer(size: canvas)

        return renderer.image { ctx in
            gapColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvas))

            let rects: [CGRect]
            switch images.count {
            case 1:
                rects = [CGRect(x: 0, y: 0, width: 1080, height: 1350)]
            case 2:
                let width = (1080 - gap) / 2
                rects = [
                    CGRect(x: 0, y: 0, width: width, height: 1350),
                    CGRect(x: width + gap, y: 0, width: width, height: 1350)
                ]
            case 3:
                let height = (1350 - gap) / 2
                let width = (1080 - gap) / 2
                rects = [
                    CGRect(x: 0, y: 0, width: 1080, height: height),
                    CGRect(x: 0, y: height + gap, width: width, height: height),
                    CGRect(x: width + gap, y: height + gap, width: width, height: height)
                ]
            default:
                let width = (1080 - gap) / 2
                let height = (1350 - gap) / 2
                rects = [
                    CGRect(x: 0, y: 0, width: width, height: height),
                    CGRect(x: width + gap, y: 0, width: width, height: height),
                    CGRect(x: 0, y: height + gap, width: width, height: height),
                    CGRect(x: width + gap, y: height + gap, width: width, height: height)
                ]
            }

            for (image, rect) in zip(images, rects) {
                ctx.cgContext.saveGState()
                ctx.cgContext.clip(to: rect)
                drawImageFill(image, in: rect, context: ctx.cgContext)
                ctx.cgContext.restoreGState()
            }
        }
    }

    private func drawImageFill(_ image: UIImage, in rect: CGRect, context: CGContext) {
        guard image.size.width > 0, image.size.height > 0 else { return }

        let imageAspect = image.size.width / image.size.height
        let rectAspect = rect.width / rect.height
        var drawRect = rect

        if imageAspect > rectAspect {
            let width = rect.height * imageAspect
            drawRect = CGRect(
                x: rect.midX - width / 2,
                y: rect.minY,
                width: width,
                height: rect.height
            )
        } else {
            let height = rect.width / imageAspect
            drawRect = CGRect(
                x: rect.minX,
                y: rect.midY - height / 2,
                width: rect.width,
                height: height
            )
        }

        UIGraphicsPushContext(context)
        image.draw(in: drawRect)
        UIGraphicsPopContext()
    }
}
