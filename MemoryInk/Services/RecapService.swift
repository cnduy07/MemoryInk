import Foundation

@MainActor
final class RecapService: ObservableObject {
    @Published private(set) var latestRecap: WeeklyRecap?
    @Published private(set) var errorMessage: String?

    private let aiService: AIService
    private let repository: JournalEntryRepository
    private let usageTracker: AIUsageTracker
    private let calendar: Calendar

    init(
        aiService: AIService,
        repository: JournalEntryRepository,
        usageTracker: AIUsageTracker,
        calendar: Calendar = .current
    ) {
        self.aiService = aiService
        self.repository = repository
        self.usageTracker = usageTracker
        self.calendar = calendar
    }

    func generateWeeklyRecapIfPossible() async {
        guard aiService.isConfigured else {
            errorMessage = nil
            return
        }

        let memories = repository.entriesSince(startOfPastWeek()).prefix(12)
        guard !memories.isEmpty else {
            errorMessage = nil
            return
        }

        let recapId = UUID()
        let request = RecapGenerationRequest(
            recapId: recapId,
            entryIds: memories.map(\.id),
            memories: memories.map(recapPayload(for:)),
            locale: Locale.current.language.languageCode?.identifier ?? "en"
        )

        do {
            usageTracker.recordRecapRequest()
            let data = try await aiService.generateRecap(request)
            latestRecap = WeeklyRecap(
                id: recapId,
                entryIds: request.entryIds,
                recap: data.recap,
                generatedAt: data.generatedAt,
                cached: data.cached
            )
            errorMessage = nil
        } catch let error as AIServiceError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Couldn't generate a recap right now."
        }
    }

    private func startOfPastWeek() -> Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -7, to: today) ?? today
    }

    private func recapPayload(for entry: JournalEntry) -> RecapMemoryPayload {
        RecapMemoryPayload(
            entryId: entry.id,
            createdAt: entry.createdAt,
            sceneLabels: [entry.mood.rawValue, entry.narrativeStyle.rawValue],
            mood: entry.mood.rawValue,
            note: entry.rawNote,
            aiNarrative: entry.aiNarrative
        )
    }
}
