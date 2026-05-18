import CoreData
import Combine
import Foundation

@MainActor
final class JournalEntryRepository: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchEntries()
    }

    func fetchEntries() {
        let request = NSFetchRequest<JournalEntryObject>(entityName: "JournalEntryObject")
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        do {
            entries = try context.fetch(request).map { $0.toDomainModel() }
        } catch {
            entries = []
        }
    }

    @discardableResult
    func createEntry(
        id: UUID,
        createdAt: Date = Date(),
        photoPath: String,
        thumbnailPath: String,
        mediumPreviewPath: String,
        rawNote: String?,
        voicePath: String?,
        mood: MoodType,
        narrativeStyle: NarrativeStyle = .warm,
        syncStatus: SyncStatus = .pending
    ) throws -> JournalEntry {
        let object = JournalEntryObject(context: context)
        object.id = id
        object.createdAt = createdAt
        object.photoPath = photoPath
        object.thumbnailPath = thumbnailPath
        object.mediumPreviewPath = mediumPreviewPath
        object.rawNote = normalized(rawNote)
        object.voicePath = normalized(voicePath)
        object.aiNarrative = nil
        object.moodRawValue = mood.rawValue
        object.narrativeStyleRawValue = narrativeStyle.rawValue
        object.syncStatusRawValue = syncStatus.rawValue
        object.aiGenerationDate = nil
        object.isFavorite = false

        try context.save()
        let entry = object.toDomainModel()
        fetchEntries()
        return entry
    }

    private func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}
