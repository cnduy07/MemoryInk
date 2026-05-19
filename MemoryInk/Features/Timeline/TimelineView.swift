import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var imagePipeline: ImagePipelineService
    @EnvironmentObject private var narrativeGenerationService: NarrativeGenerationService
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var analyticsService: AnalyticsService
    @StateObject private var viewModel = TimelineViewModel()
    @Namespace private var cardNamespace
    @State private var appearedCards: Set<UUID> = []
    @State private var selectedMemory: TimelineMemory?
    @State private var isShowingCreation = false

    var body: some View {
        NavigationStack(path: $router.path) {
            GeometryReader { proxy in
                let metrics = layoutMetrics(for: proxy.size)
                let memories = viewModel.memories(
                    from: repository.entries,
                    generationStates: narrativeGenerationService.states
                )

                ZStack {
                    background
                        .ignoresSafeArea()

                    if memories.isEmpty {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(alignment: .center, spacing: metrics.cardGap) {
                                header(isCompact: metrics.isCompact)
                                    .frame(maxWidth: metrics.cardMaxWidth, alignment: .leading)

                                ForEach(memories) { memory in
                                    TimelineCard(
                                        memory: memory,
                                        namespace: cardNamespace,
                                        isCompact: metrics.isCompact,
                                        retryAction: retryAction(for: memory)
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            selectedMemory = memory
                                        }
                                    }
                                    .frame(width: metrics.cardMaxWidth)
                                    .opacity(appearedCards.contains(memory.id) ? 1 : 0)
                                    .scaleEffect(appearedCards.contains(memory.id) ? 1 : 0.985)
                                    .blur(radius: appearedCards.contains(memory.id) ? 0 : 4)
                                    .onAppear {
                                        animateCardIn(memory.id)
                                    }
                                }
                            }
                            .padding(.horizontal, metrics.horizontalPadding)
                            .padding(.top, metrics.topPadding)
                            .padding(.bottom, 52)
                            .frame(maxWidth: .infinity)
                        }
                        .blur(radius: selectedMemory == nil ? 0 : 3.5)
                        .scaleEffect(selectedMemory == nil ? 1 : 0.992)
                        .allowsHitTesting(selectedMemory == nil)
                        .animation(.easeInOut(duration: 0.24), value: selectedMemory)
                    }

                    if selectedMemory == nil {
                        createButton
                    }

                    if let selectedMemory {
                        let currentMemory = memories.first { $0.id == selectedMemory.id } ?? selectedMemory
                        detailOverlay(for: currentMemory, metrics: metrics, viewport: proxy.size)
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
            }
            .sheet(isPresented: $isShowingCreation) {
                MemoryCreationView(
                    repository: repository,
                    imagePipeline: imagePipeline,
                    narrativeGenerationService: narrativeGenerationService,
                    analyticsService: analyticsService
                )
            }
            .task {
                analyticsService.track(.timelineSessionStarted)
                await narrativeGenerationService.generatePendingNarratives()
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                MemoryInkColors.parchment,
                MemoryInkColors.parchmentDeep,
                MemoryInkColors.paperWarm
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topTrailing) {
            RadialGradient(
                colors: [
                    Color.white.opacity(0.36),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 260
            )
            .frame(width: 260, height: 260)
            .offset(x: 72, y: -64)
        }
    }

    private func header(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 9) {
            HStack {
                Text("Private timeline")
                    .font(MemoryInkTypography.eyebrow)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    router.path.append(.settings)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }

            Text("MemoryInk")
                .font(isCompact ? .system(size: 31, weight: .semibold, design: .default) : MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text("Small moments, held quietly.")
                .font(MemoryInkTypography.subtitle)
                .foregroundStyle(MemoryInkColors.secondaryInk)

            if subscriptionManager.isPaywallEligible && !subscriptionManager.hasPremiumEntitlement {
                Button("MemoryInk+") {
                    router.path.append(.subscription)
                }
                .font(MemoryInkTypography.timestamp.weight(.medium))
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(.bottom, isCompact ? 0 : 2)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .timeline:
            TimelineView()
        case .memoryDetail:
            EmptyView()
        case .recap:
            RecapView()
        case .onThisDay:
            OnThisDayView()
        case .settings:
            SettingsView()
        case .subscription:
            if subscriptionManager.isPaywallEligible {
                SubscriptionView()
            } else {
                SubscriptionLockedView()
            }
        case .subscriptionPreview:
            SubscriptionView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Text("Your memories will appear here ✨")
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .multilineTextAlignment(.center)

            Button {
                isShowingCreation = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MemoryInkColors.ink)
                    .frame(width: 44, height: 44)
                    .background(MemoryInkColors.paper.opacity(0.92))
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
                    }
                    .shadow(color: MemoryInkColors.filmShadow.opacity(0.10), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create memory")
        }
        .padding(28)
    }

    private var createButton: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button {
                    isShowingCreation = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MemoryInkColors.ink)
                        .frame(width: 54, height: 54)
                        .background(.ultraThinMaterial)
                        .background(MemoryInkColors.paper.opacity(0.62))
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.28), lineWidth: 0.8)
                        }
                        .shadow(color: MemoryInkColors.filmShadow.opacity(0.16), radius: 22, x: 0, y: 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Create memory")
            }
            .padding(.trailing, 22)
            .padding(.bottom, 24)
        }
    }

    private func detailOverlay(for memory: TimelineMemory, metrics: TimelineLayoutMetrics, viewport: CGSize) -> some View {
        ZStack {
            MemoryInkColors.ink.opacity(0.34)
                .ignoresSafeArea()
                .onTapGesture {
                    closeDetail()
                }

            VStack(spacing: 14) {
                HStack {
                    Spacer()

                    Button {
                        closeDetail()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.22), lineWidth: 0.6)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close memory")
                }

                TimelineCard(
                    memory: memory,
                    namespace: cardNamespace,
                    isExpanded: true,
                    isCompact: metrics.isCompact,
                    retryAction: retryAction(for: memory)
                ) {
                    closeDetail()
                }
                .frame(width: metrics.detailMaxWidth)
            }
            .frame(width: metrics.detailMaxWidth)
            .padding(.horizontal, metrics.overlayPadding)
            .offset(y: metrics.isCompact ? -10 : -18)
            .transition(.opacity.combined(with: .scale(scale: 0.988)))
        }
        .background(.regularMaterial.opacity(0.70))
    }

    private func animateCardIn(_ id: UUID) {
        guard !appearedCards.contains(id) else { return }

        withAnimation(.easeOut(duration: 0.26)) {
            _ = appearedCards.insert(id)
        }
    }

    private func closeDetail() {
        withAnimation(.easeInOut(duration: 0.24)) {
            selectedMemory = nil
        }
    }

    private func retryAction(for memory: TimelineMemory) -> (() -> Void)? {
        guard memory.narrativeState.canRetry else { return nil }

        return {
            narrativeGenerationService.retry(entryId: memory.id)
        }
    }

    private func layoutMetrics(for size: CGSize) -> TimelineLayoutMetrics {
        let isCompact = size.height <= 670 || size.width <= 340
        let horizontalPadding: CGFloat = isCompact ? 14 : 20
        let availableWidth = max(size.width - (horizontalPadding * 2), 0)
        let compactWidth = max(min(availableWidth, 304), 0)
        let regularWidth = max(min(availableWidth, 430), 0)
        let overlayPadding: CGFloat = isCompact ? 14 : 20
        let availableDetailWidth = max(size.width - (overlayPadding * 2), 0)
        let detailWidth = max(min(availableDetailWidth, isCompact ? 304 : 430), 0)

        return TimelineLayoutMetrics(
            isCompact: isCompact,
            horizontalPadding: horizontalPadding,
            topPadding: isCompact ? 16 : 28,
            cardGap: isCompact ? 28 : MemoryInkSpacing.cardGap,
            cardMaxWidth: isCompact ? compactWidth : regularWidth,
            detailMaxWidth: detailWidth,
            overlayPadding: overlayPadding
        )
    }
}

private struct TimelineLayoutMetrics {
    let isCompact: Bool
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let cardGap: CGFloat
    let cardMaxWidth: CGFloat
    let detailMaxWidth: CGFloat
    let overlayPadding: CGFloat
}

struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        let stack = CoreDataStack(inMemory: true)
        let repository = JournalEntryRepository(context: stack.viewContext)
        let aiService = AIService()
        let usageTracker = AIUsageTracker()
        let narrativeService = NarrativeGenerationService(
            aiService: aiService,
            repository: repository,
            usageTracker: usageTracker
        )

        TimelineView()
            .environmentObject(AppRouter())
            .environmentObject(repository)
            .environmentObject(ImagePipelineService())
            .environmentObject(narrativeService)
            .environmentObject(SubscriptionManager())
            .environmentObject(AuthService())
            .environmentObject(
                SyncService(
                    repository: repository,
                    subscriptionManager: SubscriptionManager(),
                    authService: AuthService()
                )
            )
            .environmentObject(AnalyticsService())
    }
}

private struct SubscriptionLockedView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MemoryInk+")
                .font(MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text("This will appear after your first memory has had a moment to come alive.")
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .lineSpacing(7)
        }
        .padding(28)
        .background(MemoryInkColors.parchment.ignoresSafeArea())
    }
}
