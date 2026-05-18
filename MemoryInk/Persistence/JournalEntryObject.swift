import CoreData
import Foundation

@objc(JournalEntryObject)
final class JournalEntryObject: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var createdAt: Date
    @NSManaged var photoPath: String
    @NSManaged var thumbnailPath: String
    @NSManaged var mediumPreviewPath: String
    @NSManaged var rawNote: String?
    @NSManaged var voicePath: String?
    @NSManaged var aiNarrative: String?
    @NSManaged var moodRawValue: String
    @NSManaged var narrativeStyleRawValue: String
    @NSManaged var syncStatusRawValue: String
    @NSManaged var aiGenerationDate: Date?
    @NSManaged var isFavorite: Bool
}

extension JournalEntryObject {
    func toDomainModel() -> JournalEntry {
        JournalEntry(
            id: id,
            createdAt: createdAt,
            photoPath: photoPath,
            thumbnailPath: thumbnailPath,
            mediumPreviewPath: mediumPreviewPath,
            rawNote: rawNote,
            voicePath: voicePath,
            aiNarrative: aiNarrative,
            mood: MoodType(rawValue: moodRawValue) ?? .reflective,
            narrativeStyle: NarrativeStyle(rawValue: narrativeStyleRawValue) ?? .warm,
            syncStatus: SyncStatus(rawValue: syncStatusRawValue) ?? .pending,
            aiGenerationDate: aiGenerationDate,
            isFavorite: isFavorite
        )
    }
}
