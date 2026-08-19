import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var imagePipeline: ImagePipelineService
    @EnvironmentObject private var narrativeGenerationService: NarrativeGenerationService
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var syncService: SyncService
    @EnvironmentObject private var analyticsService: AnalyticsService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("paywall_auto_shown") private var paywallAutoShown: Bool = false
    @StateObject private var viewModel = TimelineViewModel()
    @Namespace private var cardNamespace
    @State private var appearedCards: Set<UUID> = []
    @State private var selectedMemory: TimelineMemory?
    @State private var isShowingCreation = false
    @State private var showingPaywall: Bool = false
    @State private var sharingMemory: TimelineMemory?
    @State private var milestoneToast: String?
    @FocusState private var isSearchFocused: Bool

    private let milestoneService = MilestoneService()
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack(path: $router.path) {
            GeometryReader { proxy in
                let metrics = layoutMetrics(for: proxy.size)
                let memories = viewModel.memories(
                    from: repository.entries,
                    generationStates: narrativeGenerationService.states
                )

                ZStack {
                    MemoryInkAmbientBackdrop(
                        mood: viewModel.recentInsight(from: repository.entries)?.mood,
                        intensity: 1.0
                    )
                        .ignoresSafeArea()

                    if repository.entries.isEmpty {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(alignment: .center, spacing: metrics.cardGap) {
                                header(isCompact: metrics.isCompact)
                                    .frame(maxWidth: metrics.cardMaxWidth, alignment: .leading)

                                if memories.isEmpty && viewModel.isSearching && !viewModel.searchQuery.isEmpty {
                                    EmptyStateView(message: "No memories match \"\(viewModel.searchQuery)\".")
                                        .frame(width: metrics.cardMaxWidth)
                                        .padding(.top, 18)
                                } else if memories.isEmpty, let mood = viewModel.activeMoodFilter {
                                    EmptyStateView(message: "No \(mood.title.lowercased()) memories yet.")
                                        .frame(width: metrics.cardMaxWidth)
                                        .padding(.top, 18)
                                } else if memories.isEmpty && viewModel.showingFavoritesOnly {
                                    EmptyStateView(message: "Your favorited memories will appear here.")
                                        .frame(width: metrics.cardMaxWidth)
                                        .padding(.top, 18)
                                } else if viewModel.isGridLayout {
                                    LazyVGrid(columns: gridColumns, spacing: 12) {
                                        ForEach(memories) { memory in
                                            TimelineCard(
                                                memory: memory,
                                                namespace: cardNamespace,
                                                isCompact: metrics.isCompact,
                                                isGridCompact: true,
                                                retryAction: retryAction(for: memory),
                                                onShare: { sharingMemory = memory },
                                                onFavorite: {
                                                    withAnimation(cinematicAnimation) {
                                                        repository.toggleFavorite(id: memory.id)
                                                    }
                                                }
                                            ) {
                                                if memory.voicePath?.hasPrefix("slideshows/") == true {
                                                    router.path.append(.memoryDetail(id: memory.id))
                                                } else {
                                                    router.path.append(.memoryViewer(entryId: memory.id))
                                                }
                                            }
                                            .modifier(CinematicScrollEffect(reduceMotion: reduceMotion))
                                            .opacity(appearedCards.contains(memory.id) ? 1 : 0)
                                            .scaleEffect(appearedCards.contains(memory.id) ? 1 : 0.985)
                                            .blur(radius: appearedCards.contains(memory.id) ? 0 : 4)
                                            .onAppear {
                                                animateCardIn(memory.id)
                                            }
                                        }
                                    }
                                    .frame(width: metrics.cardMaxWidth)
                                } else {
                                    ForEach(memories) { memory in
                                        TimelineCard(
                                            memory: memory,
                                            namespace: cardNamespace,
                                            isCompact: metrics.isCompact,
                                            retryAction: retryAction(for: memory),
                                            onShare: { sharingMemory = memory },
                                            onFavorite: {
                                                withAnimation(cinematicAnimation) {
                                                    repository.toggleFavorite(id: memory.id)
                                                }
                                            }
                                        ) {
                                            if memory.voicePath?.hasPrefix("slideshows/") == true {
                                                router.path.append(.memoryDetail(id: memory.id))
                                            } else {
                                                withAnimation(cinematicAnimation) {
                                                    selectedMemory = memory
                                                }
                                            }
                                        }
                                        .frame(width: metrics.cardMaxWidth)
                                        .modifier(CinematicScrollEffect(reduceMotion: reduceMotion))
                                        .opacity(appearedCards.contains(memory.id) ? 1 : 0)
                                        .scaleEffect(appearedCards.contains(memory.id) ? 1 : 0.985)
                                        .blur(radius: appearedCards.contains(memory.id) ? 0 : 4)
                                        .onAppear {
                                            animateCardIn(memory.id)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, metrics.horizontalPadding)
                            .padding(.top, metrics.topPadding)
                            .padding(.bottom, 52)
                            .frame(maxWidth: .infinity)
                        }
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                dismissEmptySearchIfNeeded()
                            }
                        )
                        .blur(radius: selectedMemory == nil ? 0 : 3.5)
                        .scaleEffect(selectedMemory == nil ? 1 : 0.992)
                        .allowsHitTesting(selectedMemory == nil)
                        .animation(cinematicAnimation, value: selectedMemory)
                    }

                    if selectedMemory == nil {
                        createButton
                    }

                    if let selectedMemory {
                        let currentMemory = memories.first { $0.id == selectedMemory.id } ?? selectedMemory
                        detailOverlay(for: currentMemory, memories: memories, metrics: metrics)
                    }

                    if let milestoneToast {
                        VStack {
                            Spacer()

                            ToastView(message: milestoneToast, isError: false)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 88)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
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
                // Day-count and anniversary milestones arrive with time passing, not with a
                // new memory — so they'd never surface if this only ran on save.
                showMilestoneIfNeeded()
            }
            .onChange(of: repository.entries.count) { _ in
                showMilestoneIfNeeded()
            }
            .onChange(of: repository.entries.count) { _ in
                Task { await syncService.syncMetadataIfAllowed() }
            }
        }
        .onChange(of: subscriptionManager.isPaywallEligible) { eligible in
            if eligible && !subscriptionManager.hasPremiumEntitlement && !paywallAutoShown {
                paywallAutoShown = true
                showingPaywall = true
            }
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                SubscriptionView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $sharingMemory) { memory in
            MemoryShareCardSheet(
                narrative: memory.narrative,
                mood: memory.mood,
                date: memory.timestamp
            )
        }
    }

    private func header(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 9) {
            if viewModel.isSearching {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MemoryInkColors.tertiaryInk)

                    TextField("Search memories…", text: $viewModel.searchQuery)
                        .font(MemoryInkTypography.narrativeCompact)
                        .foregroundStyle(MemoryInkColors.ink)
                        .focused($isSearchFocused)

                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                        } label: {
                            Image(systemName: "x.circle.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(MemoryInkColors.tertiaryInk)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(MemoryInkColors.paper.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.7)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    isSearchFocused = true
                }
                .onSubmit {
                    if viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.isSearching = false
                    }
                }
            } else {
                HStack {
                    Spacer()

                    if repository.entries.count >= 5 {
                        Button {
                            router.path.append(.browse)
                        } label: {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(MemoryInkColors.secondaryInk)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Browse memories")
                    }

                    Button {
                        withAnimation(cinematicAnimation) {
                            viewModel.isGridLayout.toggle()
                        }
                    } label: {
                        Image(systemName: viewModel.isGridLayout ? "rectangle.stack" : "square.grid.2x2")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.isGridLayout ? "Show list layout" : "Show grid layout")

                    Button {
                        router.path.append(.calendar)
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Calendar")

                    Button {
                        router.path.append(.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")

                    Button {
                        withAnimation(cinematicAnimation) {
                            viewModel.isSearching = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Search memories")
                }
            }

            Text("MemoryInk")
                .font(isCompact ? MemoryInkTypography.titleCompact : MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text("Small moments, held quietly.")
                .font(MemoryInkTypography.subtitle)
                .foregroundStyle(MemoryInkColors.secondaryInk)

            if repository.entries.count >= 1 {
                HStack(spacing: 8) {
                    let count = repository.entries.count
                    Text("\(count) \(count == 1 ? "memory" : "memories")")
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(MemoryInkColors.tertiaryInk)

                    let streak = repository.currentStreak
                    if streak >= 2 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text("\(streak)-day streak")
                                .font(MemoryInkTypography.timestamp.weight(.medium))
                        }
                        .foregroundStyle(MemoryInkColors.amber)
                    }
                }
                .padding(.top, 3)
            }

            if let insight = viewModel.recentInsight(from: repository.entries) {
                recentInsightCard(insight)
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.99)))
            }

            if repository.entries.count >= 3 {
                EmotionGraphView(entries: repository.entries)
                    .padding(.top, 6)
            }

            if repository.entries.count >= 1 {
                featureCards
                    .padding(.top, 8)
            }

            if repository.entries.count >= 3 {
                moodFilterStrip
            }

            if subscriptionManager.isPaywallEligible && !subscriptionManager.hasPremiumEntitlement {
                Button {
                    router.path.append(.subscription)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Go Premium")
                            .font(MemoryInkTypography.timestamp.weight(.semibold))
                    }
                    .foregroundStyle(MemoryInkColors.ink)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [
                                MemoryInkColors.sunlit.opacity(0.42),
                                MemoryInkColors.amber.opacity(0.30)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(MemoryInkColors.amber.opacity(0.24), lineWidth: 0.8)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.bottom, isCompact ? 0 : 2)
    }

    private func recentInsightCard(_ insight: TimelineInsight) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Circle()
                    .fill(insight.mood.tint)
                    .frame(width: 7, height: 7)
                    .shadow(color: insight.mood.tint.opacity(0.35), radius: 4)

                Text("RECENT FEELING")
                    .font(MemoryInkTypography.eyebrow)
                    .kerning(0.8)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)

                Spacer(minLength: 8)

                Text(insight.mood.title)
                    .font(MemoryInkTypography.timestamp.weight(.medium))
                    .foregroundStyle(insight.mood.tint)
            }

            Text(insight.message)
                .font(MemoryInkTypography.subtitle)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(
                colors: [
                    insight.mood.tint.opacity(0.11),
                    MemoryInkColors.paper.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(insight.mood.tint.opacity(0.22), lineWidth: 0.7)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recent feeling: \(insight.mood.title). \(insight.message)")
    }

    private var moodFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                moodFilterPill(title: "All", mood: nil, isSelected: viewModel.activeMoodFilter == nil)

                ForEach(MoodType.allCases) { mood in
                    moodFilterPill(
                        title: mood.title,
                        mood: mood,
                        isSelected: viewModel.activeMoodFilter == mood
                    )
                }
            }
            .padding(.vertical, 2)
        }
        .padding(.top, 2)
    }

    private func moodFilterPill(title: String, mood: MoodType?, isSelected: Bool) -> some View {
        Button {
            withAnimation(cinematicAnimation) {
                viewModel.activeMoodFilter = mood
            }
        } label: {
            HStack(spacing: 6) {
                if let mood {
                    Circle()
                        .fill(mood.tint)
                        .frame(width: 6, height: 6)
                }

                Text(title)
                    .font(MemoryInkTypography.timestamp.weight(.medium))
            }
            .foregroundStyle(MemoryInkColors.secondaryInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? (mood?.tint ?? MemoryInkColors.sunlit).opacity(0.22)
                    : MemoryInkColors.paper.opacity(0.72)
            )
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        isSelected
                            ? (mood?.tint ?? MemoryInkColors.sunlit).opacity(0.55)
                            : MemoryInkColors.hairline.opacity(0.24),
                        lineWidth: 0.7
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var featureCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                featurePill(icon: "chart.bar.fill", title: "Weekly Recap", tint: MemoryInkColors.teal) {
                    router.path.append(.recap)
                }
                featurePill(icon: "clock.arrow.circlepath", title: "On This Day", tint: MemoryInkColors.coral) {
                    router.path.append(.onThisDay)
                }
                featurePill(
                    icon: viewModel.showingFavoritesOnly ? "heart.fill" : "heart",
                    title: "Favorites",
                    tint: MemoryInkColors.gold,
                    isSelected: viewModel.showingFavoritesOnly
                ) {
                    withAnimation(cinematicAnimation) {
                        viewModel.showingFavoritesOnly.toggle()
                    }
                }
                if repository.entries.count >= 5 {
                    featurePill(icon: "shuffle", title: "Surprise Me", tint: MemoryInkColors.ocean) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if let memory = repository.randomEntry() {
                            router.path.append(.memoryDetail(id: memory.id))
                        }
                    }
                }
                if repository.entriesSince(oneYearAgo).count >= 10 {
                    featurePill(icon: "star.fill", title: "Year in Memories", tint: MemoryInkColors.orchid) {
                        router.path.append(.yearlyReview)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var favoritesSubtitle: String {
        let count = repository.entries.filter(\.isFavorite).count
        return count == 0 ? "Your saved memories" : "\(count) saved"
    }

    private func featurePill(
        icon: String,
        title: String,
        tint: Color,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.62)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 27, height: 27)

                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(MemoryInkTypography.timestamp.weight(.medium))
                    .foregroundStyle(MemoryInkColors.secondaryInk)
            }
            .padding(.leading, 6)
            .padding(.trailing, 13)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [
                        tint.opacity(isSelected ? 0.30 : 0.15),
                        MemoryInkColors.paper.opacity(0.72)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? tint.opacity(0.66) : tint.opacity(0.30), lineWidth: 0.8)
            }
            .shadow(color: tint.opacity(isSelected ? 0.18 : 0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(MemoryInkPressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func timelinePill(
        _ title: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .font(MemoryInkTypography.timestamp.weight(.medium))
            .foregroundStyle(MemoryInkColors.secondaryInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? MemoryInkColors.sunlit.opacity(0.22) : MemoryInkColors.paper.opacity(0.72))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        isSelected ? MemoryInkColors.sunlit.opacity(0.38) : MemoryInkColors.hairline.opacity(0.24),
                        lineWidth: 0.7
                    )
            }
            .buttonStyle(.plain)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .timeline:
            TimelineView()
        case .memoryDetail(let id):
            MemoryDetailView(entryId: id)
        case .memoryViewer(let entryId):
            MemoryViewerView(startingId: entryId)
        case .recap:
            RecapView()
        case .onThisDay:
            OnThisDayView()
        case .yearlyReview:
            YearlyReviewView()
        case .calendar:
            CalendarView()
        case .browse:
            CardBrowseView()
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

    private func detailOverlay(
        for memory: TimelineMemory,
        memories: [TimelineMemory],
        metrics: TimelineLayoutMetrics
    ) -> some View {
        let currentIndex = memories.firstIndex(where: { $0.id == memory.id })
        let canShowNewer = currentIndex.map { $0 > memories.startIndex } ?? false
        let canShowOlder = currentIndex.map { $0 + 1 < memories.count } ?? false

        return ZStack {
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
                .id(memory.id)
                .transition(.opacity.combined(with: .scale(scale: 0.985)))

                HStack(spacing: 12) {
                    if memories.count > 1 {
                        carouselButton(
                            systemName: "chevron.left",
                            accessibilityLabel: "Show newer memory",
                            isEnabled: canShowNewer
                        ) {
                            showAdjacentMemory(to: -1, from: memory, in: memories)
                        }
                    }

                    Button {
                        closeDetail()
                        router.path.append(.memoryDetail(id: memory.id))
                    } label: {
                        Text("View detail")
                            .font(MemoryInkTypography.timestamp.weight(.medium))
                            .foregroundStyle(MemoryInkColors.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(MemoryInkColors.paper.opacity(0.72))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.7)
                            }
                    }
                    .buttonStyle(.plain)

                    if memories.count > 1 {
                        carouselButton(
                            systemName: "chevron.right",
                            accessibilityLabel: "Show older memory",
                            isEnabled: canShowOlder
                        ) {
                            showAdjacentMemory(to: 1, from: memory, in: memories)
                        }
                    }
                }
            }
            .frame(width: metrics.detailMaxWidth)
            .padding(.horizontal, metrics.overlayPadding)
            .offset(y: metrics.isCompact ? -10 : -18)
            .transition(.opacity.combined(with: .scale(scale: 0.988)))
            .simultaneousGesture(
                DragGesture(minimumDistance: 44, coordinateSpace: .local)
                    .onEnded { value in
                        handleDetailSwipe(value, from: memory, in: memories)
                    }
            )
        }
        .background(.regularMaterial.opacity(0.70))
    }

    private func carouselButton(
        systemName: String,
        accessibilityLabel: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial)
                .background(MemoryInkColors.paper.opacity(0.52))
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.7)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.28)
        .accessibilityLabel(accessibilityLabel)
    }

    private func handleDetailSwipe(
        _ value: DragGesture.Value,
        from memory: TimelineMemory,
        in memories: [TimelineMemory]
    ) {
        let horizontal = abs(value.translation.width)
        let vertical = abs(value.translation.height)
        guard horizontal > vertical * 1.2, horizontal >= 52 else { return }

        showAdjacentMemory(
            to: value.translation.width > 0 ? -1 : 1,
            from: memory,
            in: memories
        )
    }

    private func showAdjacentMemory(
        to offset: Int,
        from memory: TimelineMemory,
        in memories: [TimelineMemory]
    ) {
        guard let currentIndex = memories.firstIndex(where: { $0.id == memory.id }) else {
            return
        }

        let targetIndex = currentIndex + offset
        guard memories.indices.contains(targetIndex) else { return }

        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(cinematicAnimation) {
            selectedMemory = memories[targetIndex]
        }
    }

    private func animateCardIn(_ id: UUID) {
        guard !appearedCards.contains(id) else { return }

        withAnimation(cinematicAnimation) {
            _ = appearedCards.insert(id)
        }
    }

    private func closeDetail() {
        withAnimation(cinematicAnimation) {
            selectedMemory = nil
        }
    }

    private func dismissEmptySearchIfNeeded() {
        guard viewModel.isSearching,
              viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        withAnimation(cinematicAnimation) {
            viewModel.isSearching = false
            isSearchFocused = false
        }
    }

    private func retryAction(for memory: TimelineMemory) -> (() -> Void)? {
        guard memory.narrativeState.canRetry else { return nil }

        return {
            narrativeGenerationService.retry(entryId: memory.id)
        }
    }

    private var oneYearAgo: Date {
        Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
    }

    private var cinematicAnimation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.26)
    }

    private func showMilestoneIfNeeded() {
        let message = milestoneService.check(
            entryCount: repository.entries.count,
            firstEntryDate: repository.firstEntryDate
        )

        guard let message else { return }

        withAnimation(cinematicAnimation) {
            milestoneToast = message
        }

        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)

            await MainActor.run {
                guard milestoneToast == message else { return }

                withAnimation(cinematicAnimation) {
                    milestoneToast = nil
                }
            }
        }
    }

    private func layoutMetrics(for size: CGSize) -> TimelineLayoutMetrics {
        let viewportWidth = finiteDimension(size.width)
        let viewportHeight = finiteDimension(size.height)
        let isCompact = viewportHeight <= 670 || viewportWidth <= 340
        let horizontalPadding: CGFloat = isCompact ? 14 : 20
        let availableWidth = finiteDimension(viewportWidth - (horizontalPadding * 2))
        let compactWidth = finiteDimension(min(availableWidth, 304))
        let regularWidth = finiteDimension(min(availableWidth, viewportWidth > 700 ? 580 : 430))
        let overlayPadding: CGFloat = isCompact ? 14 : 20
        let availableDetailWidth = finiteDimension(viewportWidth - (overlayPadding * 2))
        let detailWidth = finiteDimension(min(availableDetailWidth, isCompact ? 304 : (viewportWidth > 700 ? 580 : 430)))

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

    private func finiteDimension(_ value: CGFloat, fallback: CGFloat = 0) -> CGFloat {
        guard value.isFinite else {
            return fallback
        }

        return max(value, 0)
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

private struct CinematicScrollEffect: ViewModifier {
    let reduceMotion: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *), !reduceMotion {
            content
                .scrollTransition(
                    .animated(.easeInOut(duration: 0.26)),
                    axis: .vertical
                ) { view, phase in
                    view
                        .opacity(phase.isIdentity ? 1 : 0.84)
                        .scaleEffect(phase.isIdentity ? 1 : 0.975)
                }
        } else {
            content
        }
    }
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
