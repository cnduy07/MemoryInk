import SwiftUI

@main
struct MemoryInkApp: App {
    private let coreDataStack: CoreDataStack
    private let aiService: AIService
    private let usageTracker: AIUsageTracker
    private let analyticsService: AnalyticsService

    @StateObject private var router = AppRouter()
    @StateObject private var imagePipeline = ImagePipelineService()
    @StateObject private var repository: JournalEntryRepository
    @StateObject private var subscriptionManager: SubscriptionManager
    @StateObject private var authService: AuthService
    @StateObject private var syncService: SyncService
    @StateObject private var narrativeGenerationService: NarrativeGenerationService
    @StateObject private var recapService: RecapService
    @StateObject private var onThisDayService: OnThisDayService
    @StateObject private var yearlyReviewService: YearlyReviewService
    @StateObject private var notificationService = NotificationService()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("onboarding_completed") private var onboardingCompleted = false

    init() {
        let coreDataStack = CoreDataStack()
        let aiService = AIService()
        let usageTracker = AIUsageTracker()
        let analyticsService = AnalyticsService()
        let repository = JournalEntryRepository(context: coreDataStack.viewContext)
        let subscriptionManager = SubscriptionManager()
        let authService = AuthService()

        self.coreDataStack = coreDataStack
        self.aiService = aiService
        self.usageTracker = usageTracker
        self.analyticsService = analyticsService
        _repository = StateObject(
            wrappedValue: repository
        )
        _subscriptionManager = StateObject(
            wrappedValue: subscriptionManager
        )
        _authService = StateObject(
            wrappedValue: authService
        )
        _syncService = StateObject(
            wrappedValue: SyncService(
                repository: repository,
                subscriptionManager: subscriptionManager,
                authService: authService
            )
        )
        _narrativeGenerationService = StateObject(
            wrappedValue: NarrativeGenerationService(
                aiService: aiService,
                repository: repository,
                usageTracker: usageTracker,
                subscriptionManager: subscriptionManager,
                analyticsService: analyticsService
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
        _yearlyReviewService = StateObject(
            wrappedValue: YearlyReviewService(
                aiService: aiService,
                repository: repository,
                subscriptionManager: subscriptionManager
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingCompleted {
                    TimelineView()
                } else {
                    OnboardingView {
                        onboardingCompleted = true
                    }
                }
            }
            .environmentObject(router)
            .environmentObject(repository)
            .environmentObject(imagePipeline)
            .environmentObject(subscriptionManager)
            .environmentObject(authService)
            .environmentObject(syncService)
            .environmentObject(narrativeGenerationService)
            .environmentObject(recapService)
            .environmentObject(onThisDayService)
            .environmentObject(yearlyReviewService)
            .environmentObject(notificationService)
            .environmentObject(analyticsService)
            .task {
                await authService.restoreSession()
                await subscriptionManager.refreshEntitlements()
                await syncService.syncMetadataIfAllowed()
                onThisDayService.refresh()
                await notificationService.scheduleOnThisDayIfNeeded(entryCount: onThisDayService.entries.count)
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    Task { await syncService.syncMetadataIfAllowed() }
                }
            }
        }
    }
}
