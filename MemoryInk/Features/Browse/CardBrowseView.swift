import SwiftUI

struct CardBrowseView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var imagePipeline: ImagePipelineService

    private var entries: [JournalEntry] { repository.entries }

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var showFavoriteFlash: Bool = false
    @State private var showShareSheet: Bool = false

    private let swipeThreshold: CGFloat = 100
    private let rotationFactor: Double = 12.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MemoryInkColors.parchment, MemoryInkColors.parchmentDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 22)
                    .padding(.top, 8)

                Spacer(minLength: 0)

                if entries.isEmpty || currentIndex >= entries.count {
                    endState
                } else {
                    cardStack
                }

                Spacer(minLength: 0)

                if currentIndex < entries.count {
                    actionRow
                        .padding(.horizontal, 40)
                        .padding(.bottom, 32)
                }
            }

            if showFavoriteFlash {
                Image(systemName: "heart.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(MemoryInkColors.amber)
                    .scaleEffect(showFavoriteFlash ? 1.0 : 0.4)
                    .opacity(showFavoriteFlash ? 1.0 : 0.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showFavoriteFlash)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if currentIndex < entries.count {
                let entry = entries[currentIndex]
                MemoryShareCardSheet(
                    narrative: entry.aiNarrative ?? "\(entry.mood.title) memory",
                    mood: entry.mood,
                    date: entry.createdAt
                )
            }
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button {
                router.path.removeLast()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .frame(width: 36, height: 36)
                    .background(MemoryInkColors.paper.opacity(0.80))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            if !entries.isEmpty {
                Text("\(min(currentIndex + 1, entries.count)) of \(entries.count)")
                    .font(MemoryInkTypography.timestamp.weight(.medium))
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
            }

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
    }

    private var cardStack: some View {
        ZStack {
            ForEach(backgroundStackOffsets, id: \.self) { offset in
                let index = currentIndex + offset
                if index < entries.count {
                    browseCard(entry: entries[index], stackOffset: offset)
                        .allowsHitTesting(false)
                }
            }

            browseCard(entry: entries[currentIndex], stackOffset: 0)
                .offset(x: dragOffset.width, y: dragOffset.height * 0.3)
                .rotationEffect(
                    .degrees(Double(dragOffset.width) / rotationFactor),
                    anchor: UnitPoint(x: 0.5, y: 1.1)
                )
                .overlay(swipeOverlay)
                .gesture(swipeGesture)
                .zIndex(10)
        }
        .padding(.horizontal, 22)
    }

    private var backgroundStackOffsets: [Int] {
        let visibleBackgroundCount = min(2, entries.count - currentIndex - 1)
        guard visibleBackgroundCount > 0 else { return [] }

        return Array((1...visibleBackgroundCount).reversed())
    }

    private func browseCard(entry: JournalEntry, stackOffset: Int) -> some View {
        let scale = stackOffset == 0 ? 1.0 : (stackOffset == 1 ? 0.93 : 0.87)
        let yOffset: CGFloat = stackOffset == 0 ? 0 : (stackOffset == 1 ? 14 : 26)

        return BrowseCardFace(entry: entry)
            .scaleEffect(scale)
            .offset(y: yOffset)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentIndex)
    }

    private var swipeOverlay: some View {
        ZStack {
            HStack {
                VStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28, weight: .bold))
                    Text("SAVE")
                        .font(.system(size: 13, weight: .heavy))
                        .kerning(1.5)
                }
                .foregroundStyle(MemoryInkColors.sage)
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MemoryInkColors.sage.opacity(0.6), lineWidth: 2)
                }
                .opacity(Double(max(0, dragOffset.width - 20)) / 60.0)
                .rotationEffect(.degrees(-15))
                .padding(.leading, 28)
                .padding(.top, 40)

                Spacer()
            }

            HStack {
                Spacer()

                VStack(spacing: 6) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 28, weight: .bold))
                    Text("NEXT")
                        .font(.system(size: 13, weight: .heavy))
                        .kerning(1.5)
                }
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MemoryInkColors.hairline.opacity(0.6), lineWidth: 2)
                }
                .opacity(Double(max(0, -dragOffset.width - 20)) / 60.0)
                .rotationEffect(.degrees(15))
                .padding(.trailing, 28)
                .padding(.top, 40)
            }
        }
    }

    private var swipeGesture: some Gesture {
        memoryInkSwipeGesture(
            MemoryInkSwipeGestureConfig(
                minimumDistance: 10,
                useGlobalCoordinateSpace: false,
                requireHorizontalDominance: false,
                predictionWeight: 0.25,
                threshold: swipeThreshold
            ),
            onChanged: { translation in
                isDragging = true
                dragOffset = translation
            },
            onCommit: { direction in
                isDragging = false
                flyCard(direction: direction)
            },
            onCancel: {
                isDragging = false
                snapBack()
            }
        )
    }

    private func flyCard(direction: MemoryInkSwipeDirection) {
        guard currentIndex < entries.count else { return }

        let targetX: CGFloat = direction == .right ? 500 : -500
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
            dragOffset = CGSize(width: targetX, height: 0)
        }

        if direction == .right && currentIndex < entries.count {
            repository.toggleFavorite(id: entries[currentIndex].id)
            showFavoriteFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                showFavoriteFlash = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            currentIndex = min(currentIndex + 1, entries.count)
            dragOffset = .zero
        }
    }

    private func snapBack() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.80)) {
            dragOffset = .zero
        }
    }

    private var actionRow: some View {
        HStack(spacing: 28) {
            actionButton(
                icon: "forward.fill",
                color: MemoryInkColors.secondaryInk,
                background: MemoryInkColors.paper.opacity(0.90),
                size: 52
            ) {
                flyCard(direction: .left)
            }

            actionButton(
                icon: "square.and.arrow.up",
                color: MemoryInkColors.mistBlue,
                background: MemoryInkColors.mistBlue.opacity(0.12),
                size: 46
            ) {
                showShareSheet = true
            }

            actionButton(
                icon: currentIndex < entries.count && entries[currentIndex].isFavorite ? "heart.fill" : "heart",
                color: MemoryInkColors.amber,
                background: MemoryInkColors.amber.opacity(0.12),
                size: 52
            ) {
                flyCard(direction: .right)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func actionButton(
        icon: String,
        color: Color,
        background: Color,
        size: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(color.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: color.opacity(0.12), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var endState: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(MemoryInkColors.sage)

            Text("You've seen all your memories.")
                .font(MemoryInkTypography.subtitle)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .multilineTextAlignment(.center)

            Button("Start over") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    currentIndex = 0
                    dragOffset = .zero
                }
            }
            .font(MemoryInkTypography.narrativeCompact.weight(.medium))
            .foregroundStyle(MemoryInkColors.ink)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(MemoryInkColors.paper.opacity(0.90))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(MemoryInkColors.hairline.opacity(0.22), lineWidth: 0.8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
    }
}

struct BrowseCardFace: View {
    @EnvironmentObject private var imagePipeline: ImagePipelineService
    let entry: JournalEntry

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            ZStack(alignment: .bottomLeading) {
                Group {
                    if let image = ImagePipelineService.image(forRelativePath: entry.thumbnailPath) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [entry.mood.tint.opacity(0.8), entry.mood.tint.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: w, height: 520)
                .clipped()
                .contentShape(Rectangle())

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: w, height: 520)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(entry.mood.tint)
                            .frame(width: 6, height: 6)

                        Text(entry.mood.title.uppercased())
                            .font(MemoryInkTypography.badge)
                            .kerning(0.6)
                            .foregroundStyle(MemoryInkColors.ink)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                    if let narrative = entry.aiNarrative, !narrative.isEmpty {
                        Text(narrative)
                            .font(MemoryInkTypography.narrativeCompact)
                            .foregroundStyle(.white.opacity(0.92))
                            .lineSpacing(5)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                    }

                    Text(entry.createdAt.formatted(date: .long, time: .omitted))
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(.white.opacity(0.62))
                }
                .padding(22)
                .frame(width: w, alignment: .leading)
            }
            .frame(width: w, height: 520)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                if entry.voicePath?.hasPrefix("slideshows/") == true {
                    Image(systemName: "film.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.38))
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.28), lineWidth: 0.6)
                        }
                        .padding(14)
                }
            }
            .shadow(color: Color.black.opacity(0.22), radius: 28, x: 0, y: 18)
        }
        .frame(height: 520)
    }
}
