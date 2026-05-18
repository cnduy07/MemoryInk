import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var imagePipeline: ImagePipelineService
    @StateObject private var viewModel = TimelineViewModel()
    @Namespace private var cardNamespace
    @State private var appearedCards: Set<UUID> = []
    @State private var selectedMemory: TimelineMemory?
    @State private var isShowingCreation = false

    var body: some View {
        NavigationStack(path: $router.path) {
            GeometryReader { proxy in
                let metrics = layoutMetrics(for: proxy.size)
                let memories = viewModel.memories(from: repository.entries)

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
                                    TimelineCard(memory: memory, namespace: cardNamespace, isCompact: metrics.isCompact) {
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
                        detailOverlay(for: selectedMemory, metrics: metrics, viewport: proxy.size)
                    }
                }
                .navigationBarHidden(true)
            }
            .sheet(isPresented: $isShowingCreation) {
                MemoryCreationView(
                    repository: repository,
                    imagePipeline: imagePipeline
                )
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
            Text("Private timeline")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            Text("MemoryInk")
                .font(isCompact ? .system(size: 31, weight: .semibold, design: .default) : MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text("Small moments, held quietly.")
                .font(MemoryInkTypography.subtitle)
                .foregroundStyle(MemoryInkColors.secondaryInk)
        }
        .padding(.bottom, isCompact ? 0 : 2)
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

                TimelineCard(memory: memory, namespace: cardNamespace, isExpanded: true, isCompact: metrics.isCompact) {
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

    private func layoutMetrics(for size: CGSize) -> TimelineLayoutMetrics {
        let isCompact = size.height <= 670 || size.width <= 340
        let horizontalPadding: CGFloat = isCompact ? 14 : 20
        let availableWidth = size.width - (horizontalPadding * 2)
        let compactWidth = min(availableWidth, 304)
        let regularWidth = min(availableWidth, 430)
        let overlayPadding: CGFloat = isCompact ? 14 : 20
        let detailWidth = min(size.width - (overlayPadding * 2), isCompact ? 304 : 430)

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

        TimelineView()
            .environmentObject(AppRouter())
            .environmentObject(repository)
            .environmentObject(ImagePipelineService())
    }
}
