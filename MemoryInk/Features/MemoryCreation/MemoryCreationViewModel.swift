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
    @Published var selectedImage: UIImage?
    @Published var note: String = ""
    @Published var selectedMood: MoodType = .reflective
    @Published var saveState: SaveState = .idle

    private let repository: JournalEntryRepository
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
            saveState = .idle
        } catch {
            saveState = .failed
        }
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

            saveState = .saved
            analyticsService?.track(.firstEntryCreated)

            Task {
                await narrativeGenerationService.generateNarrativeIfNeeded(for: entry)
            }
        } catch {
            saveState = .failed
        }
    }
}
