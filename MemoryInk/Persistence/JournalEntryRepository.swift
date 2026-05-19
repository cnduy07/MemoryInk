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

    func entry(id: UUID) -> JournalEntry? {
        entryObject(id: id)?.toDomainModel()
    }

    func updateNarrative(
        _ narrative: String,
        generatedAt: Date,
        for id: UUID
    ) {
        guard let object = entryObject(id: id) else { return }

        object.aiNarrative = normalized(narrative)
        object.aiGenerationDate = generatedAt
        object.syncStatusRawValue = SyncStatus.pending.rawValue

        saveAndRefresh()
    }

    func updateSyncStatus(_ status: SyncStatus, for id: UUID) {
        guard let object = entryObject(id: id) else { return }

        object.syncStatusRawValue = status.rawValue
        saveAndRefresh()
    }

    func pendingLocalEntries() -> [JournalEntry] {
        entries.filter { entry in
            entry.syncStatus == .pending || entry.syncStatus == .failed
        }
    }

    func markSyncing(_ ids: [UUID]) {
        updateSyncStatus(.syncing, ids: ids)
    }

    func markSyncCompleted(_ ids: [UUID]) {
        updateSyncStatus(.completed, ids: ids)
    }

    func markSyncFailed(_ ids: [UUID]) {
        updateSyncStatus(.failed, ids: ids)
    }

    func applyRemoteMetadataUpdate(_ record: SyncMetadataRecord) {
        guard let object = entryObject(id: record.id) else { return }

        if record.deletedAt != nil {
            object.syncStatusRawValue = SyncStatus.completed.rawValue
            saveAndRefresh()
            return
        }

        let localRecord = SyncMetadataRecord(entry: object.toDomainModel(), userId: record.userId, updatedAt: object.createdAt)
        let resolved = SyncConflictResolver.resolve(local: localRecord, remote: record)
        guard resolved == record else { return }

        object.rawNote = normalized(record.rawNote)
        object.aiNarrative = normalized(record.aiNarrative)
        object.aiGenerationDate = record.aiGenerationDate
        object.moodRawValue = MoodType(rawValue: record.mood)?.rawValue ?? object.moodRawValue
        object.narrativeStyleRawValue = NarrativeStyle(rawValue: record.narrativeStyle)?.rawValue ?? object.narrativeStyleRawValue
        object.isFavorite = record.isFavorite
        object.syncStatusRawValue = SyncStatus.completed.rawValue

        saveAndRefresh()
    }

    func entriesSince(_ date: Date) -> [JournalEntry] {
        entries.filter { $0.createdAt >= date }
    }

    func entriesMatchingMonthAndDay(
        _ date: Date,
        excludingYear year: Int,
        calendar: Calendar = .current
    ) -> [JournalEntry] {
        let targetComponents = calendar.dateComponents([.month, .day], from: date)

        return entries.filter { entry in
            let components = calendar.dateComponents([.year, .month, .day], from: entry.createdAt)
            return components.year != year
                && components.month == targetComponents.month
                && components.day == targetComponents.day
        }
    }

    private func entryObject(id: UUID) -> JournalEntryObject? {
        let request = NSFetchRequest<JournalEntryObject>(entityName: "JournalEntryObject")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        return try? context.fetch(request).first
    }

    private func saveAndRefresh() {
        do {
            try context.save()
            fetchEntries()
        } catch {
            context.rollback()
        }
    }

    private func updateSyncStatus(_ status: SyncStatus, ids: [UUID]) {
        ids.forEach { id in
            entryObject(id: id)?.syncStatusRawValue = status.rawValue
        }
        saveAndRefresh()
    }

    private func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}
