import Foundation

enum NarrativeDisplayState: Hashable {
    case generated
    case pending
    case generating
    case timeout
    case rateLimited
    case failed

    var message: String? {
        switch self {
        case .generated:
            return nil
        case .pending, .generating:
            return "Narrative will appear shortly."
        case .timeout:
            return "Narrative generation is taking longer than expected."
        case .rateLimited:
            return "AI is taking a short break. Try again later."
        case .failed:
            return "Couldn't generate a narrative right now."
        }
    }

    var canRetry: Bool {
        switch self {
        case .timeout, .rateLimited, .failed:
            return true
        case .generated, .pending, .generating:
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
    private let defaults: UserDefaults
    private var inFlightEntryIds: Set<UUID> = []

    init(
        aiService: AIService,
        repository: JournalEntryRepository,
        usageTracker: AIUsageTracker,
        subscriptionManager: SubscriptionManager? = nil,
        analyticsService: AnalyticsService? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.aiService = aiService
        self.repository = repository
        self.usageTracker = usageTracker
        self.subscriptionManager = subscriptionManager
        self.analyticsService = analyticsService
        self.defaults = defaults
        self.states = Dictionary(
            uniqueKeysWithValues: repository.entries.compactMap { entry in
                guard let state = Self.storedState(for: entry.id, defaults: defaults) else {
                    return nil
                }

                return (entry.id, state)
            }
        )
    }

    func generatePendingNarratives() async {
        // Narrative generation is intentionally save-triggered only. Timeline/detail views
        // must not turn pending placeholders into repeated backend calls.
    }

    func retry(entryId: UUID) {
        guard let entry = repository.entry(id: entryId) else { return }

        Task {
            clearStoredState(for: entry.id)
            await generateNarrativeIfNeeded(for: entry, allowsRetryAfterFailure: true)
        }
    }

    func generateNarrativeIfNeeded(
        for entry: JournalEntry,
        allowsRetryAfterFailure: Bool = false
    ) async {
        guard entry.aiNarrative?.isEmpty != false else {
            states[entry.id] = .generated
            clearStoredState(for: entry.id)
            log("AI skipped because already generated")
            return
        }

        if let state = states[entry.id],
           state.isFailureState,
           !allowsRetryAfterFailure {
            log("AI skipped because already failed")
            return
        }

        guard !inFlightEntryIds.contains(entry.id) else {
            log("AI skipped because request already in flight")
            return
        }

        guard aiService.isConfigured else {
            states[entry.id] = .pending
            return
        }

        if let subscriptionManager,
           !usageTracker.canGenerateNarrative(limit: subscriptionManager.dailyNarrativeLimit) {
            states[entry.id] = .rateLimited
            storeState(.rateLimited, for: entry.id)
            log("AI request failed with code: RATE_LIMIT_REACHED")
            return
        }

        inFlightEntryIds.insert(entry.id)
        defer {
            inFlightEntryIds.remove(entry.id)
        }

        states[entry.id] = .generating
        clearStoredState(for: entry.id)
        log("AI request started")

        do {
            let data = try await aiService.generateNarrative(request(for: entry))
            usageTracker.recordNarrativeRequest()
            repository.updateNarrative(
                data.narrative,
                generatedAt: data.generatedAt,
                for: entry.id
            )
            states[entry.id] = .generated
            clearStoredState(for: entry.id)
            subscriptionManager?.markFirstEmotionalMomentSeen()
            analyticsService?.track(.firstNarrativeGenerated)
            log("AI request succeeded")
        } catch let error as AIServiceError {
            handle(error, for: entry.id)
        } catch {
            states[entry.id] = .failed
            storeState(.failed, for: entry.id)
            log("AI request failed with code: UNKNOWN_ERROR")
        }
    }

    private func handle(_ error: AIServiceError, for entryId: UUID) {
        switch error {
        case .notConfigured:
            states[entryId] = .pending
            clearStoredState(for: entryId)
        case .unauthorized, .networkUnavailable:
            states[entryId] = .failed
            storeState(.failed, for: entryId)
        case .timeout:
            states[entryId] = .timeout
            storeState(.timeout, for: entryId)
        case .rateLimitReached:
            states[entryId] = .rateLimited
            storeState(.rateLimited, for: entryId)
        case .validationFailed, .serviceUnavailable, .malformedResponse:
            states[entryId] = .failed
            storeState(.failed, for: entryId)
        }

        log("AI request failed with code: \(error.logCode)")
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

    private func log(_ message: String) {
        print("[MemoryInk][AI] \(message)")
    }

    private func storeState(_ state: NarrativeDisplayState, for entryId: UUID) {
        defaults.set(state.storageValue, forKey: Self.stateKey(for: entryId))
    }

    private func clearStoredState(for entryId: UUID) {
        defaults.removeObject(forKey: Self.stateKey(for: entryId))
    }

    private static func storedState(for entryId: UUID, defaults: UserDefaults) -> NarrativeDisplayState? {
        guard let value = defaults.string(forKey: stateKey(for: entryId)) else {
            return nil
        }

        return NarrativeDisplayState(storageValue: value)
    }

    private static func stateKey(for entryId: UUID) -> String {
        "ai_narrative_state_\(entryId.uuidString)"
    }
}

private extension NarrativeDisplayState {
    var storageValue: String {
        switch self {
        case .generated:
            return "generated"
        case .pending:
            return "pending"
        case .generating:
            return "generating"
        case .timeout:
            return "timeout"
        case .rateLimited:
            return "rate_limited"
        case .failed:
            return "failed"
        }
    }

    init?(storageValue: String) {
        switch storageValue {
        case "pending":
            self = .pending
        case "generating":
            self = .pending
        case "timeout":
            self = .timeout
        case "rate_limited":
            self = .rateLimited
        case "failed":
            self = .failed
        case "generated":
            self = .generated
        default:
            return nil
        }
    }

    var isFailureState: Bool {
        switch self {
        case .timeout, .rateLimited, .failed:
            return true
        case .generated, .pending, .generating:
            return false
        }
    }
}

private extension AIServiceError {
    var logCode: String {
        switch self {
        case .notConfigured:
            return "NOT_CONFIGURED"
        case .unauthorized:
            return "UNAUTHORIZED"
        case .rateLimitReached:
            return "RATE_LIMIT_REACHED"
        case .networkUnavailable:
            return "NETWORK_UNAVAILABLE"
        case .timeout:
            return "AI_TIMEOUT"
        case .validationFailed:
            return "VALIDATION_FAILED"
        case .serviceUnavailable:
            return "SERVICE_UNAVAILABLE"
        case .malformedResponse:
            return "MALFORMED_RESPONSE"
        }
    }
}
