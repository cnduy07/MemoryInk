import SwiftUI

@main
struct MemoryInkApp: App {
    private let coreDataStack: CoreDataStack
    private let aiService: AIService
    private let usageTracker: AIUsageTracker

    @StateObject private var router = AppRouter()
    @StateObject private var imagePipeline = ImagePipelineService()
    @StateObject private var repository: JournalEntryRepository
    @StateObject private var narrativeGenerationService: NarrativeGenerationService
    @StateObject private var recapService: RecapService
    @StateObject private var onThisDayService: OnThisDayService

    init() {
        let coreDataStack = CoreDataStack()
        let aiService = AIService()
        let usageTracker = AIUsageTracker()
        let repository = JournalEntryRepository(context: coreDataStack.viewContext)

        self.coreDataStack = coreDataStack
        self.aiService = aiService
        self.usageTracker = usageTracker
        _repository = StateObject(
            wrappedValue: repository
        )
        _narrativeGenerationService = StateObject(
            wrappedValue: NarrativeGenerationService(
                aiService: aiService,
                repository: repository,
                usageTracker: usageTracker
            )
        )
        _recapService = StateObject(
            wrappedValue: RecapService(
                aiService: aiService,
                repository: repository,
                usageTracker: usageTracker
            )
        )
        _onThisDayService = StateObject(
            wrappedValue: OnThisDayService(repository: repository)
        )
    }

    var body: some Scene {
        WindowGroup {
            TimelineView()
                .environmentObject(router)
                .environmentObject(repository)
                .environmentObject(imagePipeline)
                .environmentObject(narrativeGenerationService)
                .environmentObject(recapService)
                .environmentObject(onThisDayService)
        }
    }
}
