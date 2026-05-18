import Foundation

struct JournalEntry: Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let photoPath: String
    let thumbnailPath: String
    let mediumPreviewPath: String
    let rawNote: String?
    let voicePath: String?
    let aiNarrative: String?
    let mood: MoodType
    let narrativeStyle: NarrativeStyle
    let syncStatus: SyncStatus
    let aiGenerationDate: Date?
    let isFavorite: Bool
}
