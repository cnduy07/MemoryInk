import Foundation

struct YearlyReview: Codable {
    let narrative: String
    let generatedAt: Date
    let entryCount: Int
    let thumbnailPaths: [String]
}

@MainActor
final class YearlyReviewService: ObservableObject {
    @Published private(set) var review: YearlyReview?
    @Published private(set) var isGenerating = false
    @Published private(set) var errorMessage: String?

    private let aiService: AIService
    private let repository: JournalEntryRepository
    private let subscriptionManager: SubscriptionManager
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        aiService: AIService,
        repository: JournalEntryRepository,
        subscriptionManager: SubscriptionManager,
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.aiService = aiService
        self.repository = repository
        self.subscriptionManager = subscriptionManager
        self.defaults = defaults
        self.calendar = calendar

        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadCachedReview()
    }

    var currentYear: Int {
        calendar.component(.year, from: Date())
    }

    func generateIfPossible() async {
        guard subscriptionManager.hasPremiumEntitlement else {
            errorMessage = "MemoryInk+ is required for your year in memories."
            return
        }

        if review != nil {
            errorMessage = nil
            return
        }

        guard aiService.isConfigured else {
            errorMessage = "Your year in memories will appear when AI is available."
            return
        }

        let entries = repository.entriesSince(startOfYearWindow())
        guard entries.count >= 10 else {
            errorMessage = "Your year in memories will appear when there is enough to reflect on."
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        let request = RecapGenerationRequest(
            recapId: UUID(),
            entryIds: entries.map(\.id),
            memories: entries.map(recapPayload(for:)),
            locale: Locale.current.language.languageCode?.identifier ?? "en"
        )

        do {
            let data = try await aiService.generateRecap(request)
            let yearlyReview = YearlyReview(
                narrative: data.recap,
                generatedAt: data.generatedAt,
                entryCount: entries.count,
                thumbnailPaths: Array(entries.map(\.thumbnailPath).prefix(9))
            )
            review = yearlyReview
            errorMessage = nil
            save(yearlyReview)
        } catch let error as AIServiceError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Couldn't generate your year in memories right now."
        }
    }

    private func loadCachedReview() {
        guard let data = defaults.data(forKey: cacheKey),
              let cached = try? decoder.decode(YearlyReview.self, from: data) else {
            return
        }

        review = cached
    }

    private func save(_ review: YearlyReview) {
        guard let data = try? encoder.encode(review) else { return }
        defaults.set(data, forKey: cacheKey)
    }

    private var cacheKey: String {
        "yearly_review_\(currentYear)"
    }

    private func startOfYearWindow() -> Date {
        calendar.date(byAdding: .day, value: -365, to: Date()) ?? Date()
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
