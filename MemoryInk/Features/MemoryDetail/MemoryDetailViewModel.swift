import Foundation

@MainActor
final class MemoryDetailViewModel {
    private let entryId: UUID
    private let repository: JournalEntryRepository
    private let narrativeGenerationService: NarrativeGenerationService

    init(
        entryId: UUID,
        repository: JournalEntryRepository,
        narrativeGenerationService: NarrativeGenerationService
    ) {
        self.entryId = entryId
        self.repository = repository
        self.narrativeGenerationService = narrativeGenerationService
    }

    var entry: JournalEntry? {
        repository.entry(id: entryId)
    }

    var narrativeState: NarrativeDisplayState {
        if let narrative = entry?.aiNarrative, !narrative.isEmpty {
            return .generated
        }

        return narrativeGenerationService.states[entryId] ?? .pending
    }

    func toggleFavorite() {
        repository.toggleFavorite(id: entryId)
        refresh()
    }

    func delete() {
        repository.delete(id: entryId)
        NotificationCenter.default.post(name: Notification.Name("memoryDeleted"), object: nil)
    }

    func update(mood: MoodType, note: String) {
        repository.update(id: entryId, mood: mood, note: note)
        repository.clearNarrative(id: entryId)

        if let entry = repository.entry(id: entryId) {
            narrativeGenerationService.requestNarrative(for: entry)
        }

        refresh()
    }

    func retry() {
        narrativeGenerationService.retry(entryId: entryId)
        refresh()
    }

    private func refresh() {
        _ = entry
        _ = narrativeState
    }
}

private extension NarrativeGenerationService {
    func requestNarrative(for entry: JournalEntry) {
        Task {
            await generateNarrativeIfNeeded(for: entry)
        }
    }
}
