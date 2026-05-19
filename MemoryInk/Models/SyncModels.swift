import Foundation

struct SyncMetadataRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let rawNote: String?
    let mood: String
    let narrativeStyle: String
    let aiNarrative: String?
    let aiGenerationDate: Date?
    let isFavorite: Bool
    let syncStatus: String
    let localPhotoExists: Bool
    let localVoiceExists: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case rawNote = "raw_note"
        case mood
        case narrativeStyle = "narrative_style"
        case aiNarrative = "ai_narrative"
        case aiGenerationDate = "ai_generation_date"
        case isFavorite = "is_favorite"
        case syncStatus = "sync_status"
        case localPhotoExists = "local_photo_exists"
        case localVoiceExists = "local_voice_exists"
    }

    init(
        entry: JournalEntry,
        userId: String,
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus? = nil
    ) {
        self.id = entry.id
        self.userId = userId
        self.createdAt = entry.createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.rawNote = entry.rawNote
        self.mood = entry.mood.rawValue
        self.narrativeStyle = entry.narrativeStyle.rawValue
        self.aiNarrative = entry.aiNarrative
        self.aiGenerationDate = entry.aiGenerationDate
        self.isFavorite = entry.isFavorite
        self.syncStatus = syncStatus?.rawValue ?? entry.syncStatus.rawValue
        self.localPhotoExists = true
        self.localVoiceExists = entry.voicePath != nil
    }
}

enum SyncConflictResolver {
    static func resolve(local: SyncMetadataRecord, remote: SyncMetadataRecord) -> SyncMetadataRecord {
        if let remoteDeletedAt = remote.deletedAt {
            if local.deletedAt == nil || remoteDeletedAt >= (local.deletedAt ?? .distantPast) {
                return remote
            }
        }

        if let localDeletedAt = local.deletedAt {
            if remote.deletedAt == nil || localDeletedAt >= (remote.deletedAt ?? .distantPast) {
                return local
            }
        }

        return remote.updatedAt >= local.updatedAt ? remote : local
    }
}
