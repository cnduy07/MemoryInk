import Foundation

enum NarrativeDisplayState: Hashable {
    case generated
    case pending
    case timeout
    case rateLimited
    case failed

    var message: String? {
        switch self {
        case .generated:
            return nil
        case .pending:
            return "Narrative will appear shortly."
        case .timeout:
            return "Narrative generation is taking longer than expected."
        case .rateLimited:
            return "You've reached today's AI limit."
        case .failed:
            return "Couldn't generate a narrative right now."
        }
    }

    var canRetry: Bool {
        switch self {
        case .timeout, .failed:
            return true
        case .generated, .pending, .rateLimited:
            return false
        }
    }
}

@MainActor
final class NarrativeGenerationService: ObservableObject {
    @Published private(set) var states: [UUID: NarrativeDisplayState] = [:]

    private let aiService: AIService
    private let repository: JournalEntryRepository
    private let usageTracker: AIUsageTracker
    private let subscriptionManager: SubscriptionManager?
    private let analyticsService: AnalyticsService?

    init(
        aiService: AIService,
        repository: JournalEntryRepository,
        usageTracker: AIUsageTracker,
        subscriptionManager: SubscriptionManager? = nil,
        analyticsService: AnalyticsService? = nil
    ) {
        self.aiService = aiService
        self.repository = repository
        self.usageTracker = usageTracker
        self.subscriptionManager = subscriptionManager
        self.analyticsService = analyticsService
    }

    func generatePendingNarratives() async {
        let pendingEntries = repository.entries.filter { entry in
            entry.aiNarrative?.isEmpty != false && entry.syncStatus != .failed
        }

        for entry in pendingEntries {
            await generateNarrativeIfNeeded(for: entry)
        }
    }

    func retry(entryId: UUID) {
        guard let entry = repository.entry(id: entryId) else { return }

        Task {
            await generateNarrativeIfNeeded(for: entry, allowsRetryAfterFailure: true)
        }
    }

    func generateNarrativeIfNeeded(
        for entry: JournalEntry,
        allowsRetryAfterFailure: Bool = false
    ) async {
        guard entry.aiNarrative?.isEmpty != false else {
            states[entry.id] = .generated
            return
        }

        if entry.syncStatus == .failed && !allowsRetryAfterFailure {
            states[entry.id] = .failed
            return
        }

        guard aiService.isConfigured else {
            states[entry.id] = .pending
            return
        }

        if let subscriptionManager,
           !usageTracker.canGenerateNarrative(limit: subscriptionManager.dailyNarrativeLimit) {
            states[entry.id] = .rateLimited
            return
        }

        states[entry.id] = .pending
        repository.updateSyncStatus(.syncing, for: entry.id)

        do {
            usageTracker.recordNarrativeRequest()
            let data = try await aiService.generateNarrative(request(for: entry))
            repository.updateNarrative(
                data.narrative,
                generatedAt: data.generatedAt,
                for: entry.id
            )
            states[entry.id] = .generated
            subscriptionManager?.markFirstEmotionalMomentSeen()
            analyticsService?.track(.firstNarrativeGenerated)
        } catch let error as AIServiceError {
            handle(error, for: entry.id)
        } catch {
            states[entry.id] = .failed
            repository.updateSyncStatus(.failed, for: entry.id)
        }
    }

    private func handle(_ error: AIServiceError, for entryId: UUID) {
        switch error {
        case .notConfigured, .networkUnavailable:
            states[entryId] = .pending
            repository.updateSyncStatus(.pending, for: entryId)
        case .timeout:
            states[entryId] = .timeout
            repository.updateSyncStatus(.failed, for: entryId)
        case .rateLimitReached:
            states[entryId] = .rateLimited
            repository.updateSyncStatus(.failed, for: entryId)
        case .validationFailed, .serviceUnavailable, .malformedResponse:
            states[entryId] = .failed
            repository.updateSyncStatus(.failed, for: entryId)
        }
    }

    private func request(for entry: JournalEntry) -> NarrativeGenerationRequest {
        NarrativeGenerationRequest(
            entryId: entry.id,
            sceneLabels: semanticLabels(for: entry),
            mood: entry.mood.rawValue,
            note: entry.rawNote,
            narrativeStyle: entry.narrativeStyle.rawValue,
            locale: Locale.current.language.languageCode?.identifier ?? "en"
        )
    }

    private func semanticLabels(for entry: JournalEntry) -> [String] {
        var labels = [entry.mood.rawValue, entry.narrativeStyle.rawValue]

        if let note = entry.rawNote {
            let noteLabels = note
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 4 }
                .prefix(6)

            labels.append(contentsOf: noteLabels)
        }

        return Array(NSOrderedSet(array: labels)) as? [String] ?? labels
    }
}
