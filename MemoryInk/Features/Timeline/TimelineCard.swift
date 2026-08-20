import SwiftUI
import UIKit
import AVFoundation

struct TimelineCard: View {
    @EnvironmentObject private var imagePipeline: ImagePipelineService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let memory: TimelineMemory
    let isExpanded: Bool
    let isCompact: Bool
    let isGridCompact: Bool
    let retryAction: (() -> Void)?
    var onShare: (() -> Void)?
    var onFavorite: (() -> Void)?
    let onTap: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var thumbnail: UIImage?
    @State private var imageRevealed = false
    private let swipeThreshold: CGFloat = 100

    init(
        memory: TimelineMemory,
        isExpanded: Bool = false,
        isCompact: Bool = false,
        isGridCompact: Bool = false,
        retryAction: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onFavorite: (() -> Void)? = nil,
        onTap: @escaping () -> Void
    ) {
        self.memory = memory
        self.isExpanded = isExpanded
        self.isCompact = isCompact
        self.isGridCompact = isGridCompact
        self.retryAction = retryAction
        self.onShare = onShare
        self.onFavorite = onFavorite
        self.onTap = onTap
    }

    var body: some View {
        if isGridCompact {
            gridBody
        } else {
            listBody
        }
    }

    private var listBody: some View {
        ZStack {
            HStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(MemoryInkColors.sage)
                        .frame(width: 56, height: 56)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(MemoryInkColors.onAccent)
                }
                .scaleEffect(hintScale(for: dragX, positive: true))
                .opacity(hintOpacity(for: dragX, positive: true))
                .padding(.leading, 8)

                Spacer()

                ZStack {
                    Circle()
                        .fill(MemoryInkColors.mistBlue)
                        .frame(width: 56, height: 56)
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(hintScale(for: dragX, positive: false))
                .opacity(hintOpacity(for: dragX, positive: false))
                .padding(.trailing, 8)
            }

            listCard
                .offset(x: dragX)
                .rotationEffect(
                    reduceMotion ? .zero : .degrees(Double(dragX) / 24.0),
                    anchor: UnitPoint(x: 0.5, y: 1.1)
                )
                .simultaneousGesture(
                    memoryInkSwipeGesture(
                        MemoryInkSwipeGestureConfig(
                            minimumDistance: 20,
                            useGlobalCoordinateSpace: true,
                            requireHorizontalDominance: true,
                            predictionWeight: 0.22,
                            threshold: swipeThreshold
                        ),
                        onChanged: { translation in dragX = translation.width },
                        onCommit: { direction in commitSwipe(right: direction == .right) },
                        onCancel: springBack
                    ),
                    including: isExpanded ? .none : .all
                )
        }
    }

    private var listCard: some View {
        VStack(alignment: .leading, spacing: isCompact ? 12 : 16) {
            imageArea

            VStack(alignment: .leading, spacing: isCompact ? 8 : 10) {
                Text(memory.narrative)
                    .font(isCompact ? MemoryInkTypography.narrativeCompact : MemoryInkTypography.narrative)
                    .foregroundStyle(memory.narrativeState == .generated ? MemoryInkColors.ink : MemoryInkColors.secondaryInk)
                    .lineSpacing(isCompact ? 5 : 7)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if memory.narrativeState == .pending {
                    pendingLabel
                }

                if let retryAction {
                    retryControl(action: retryAction)
                }

                timestampRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(isCompact ? 16 : MemoryInkSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    MemoryInkColors.paper,
                    MemoryInkColors.paperWarm
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.20), lineWidth: 0.7)
        }
        .shadow(color: MemoryInkColors.filmShadow.opacity(isExpanded ? 0.16 : 0.10), radius: isExpanded ? 28 : 18, x: 0, y: isExpanded ? 16 : 10)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Play Video", systemImage: "play.fill")
            }
            if let onShare {
                Button {
                    onShare()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        } preview: {
            if memory.voicePath?.hasPrefix("slideshows/") == true,
               let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let url = docsURL.appendingPathComponent(memory.voicePath!)
                SilentVideoPreview(url: url)
                    .frame(width: 300, height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous))
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(memory.mood.title) memory from \(memory.timestamp.formatted(date: .abbreviated, time: .shortened))")
    }

    private var gridBody: some View {
        imageArea
            .overlay(alignment: .bottomLeading) {
                dateStamp
                    .padding(10)
            }
            .overlay(alignment: .bottomTrailing) {
                if memory.isFavorite {
                    favoriteBadge
                        .padding(10)
                }
            }
            .overlay(alignment: .topTrailing) {
                if memory.voicePath?.hasPrefix("slideshows/") == true {
                    videoBadge
                        .padding(10)
                }
            }
            .contextMenu {
                Button {
                    onTap()
                } label: {
                    Label("Play Video", systemImage: "play.fill")
                }
                if let onShare {
                    Button {
                        onShare()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            } preview: {
                if memory.voicePath?.hasPrefix("slideshows/") == true,
                   let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let url = docsURL.appendingPathComponent(memory.voicePath!)
                    SilentVideoPreview(url: url)
                        .frame(width: 300, height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .shadow(color: MemoryInkColors.filmShadow.opacity(0.10), radius: 14, x: 0, y: 8)
            .contentShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(memory.mood.title) memory from \(memory.timestamp.formatted(date: .abbreviated, time: .shortened))")
    }

    // MARK: - Swipe helpers

    private func hintScale(for offset: CGFloat, positive: Bool) -> CGFloat {
        let magnitude = positive ? max(0, offset - 30) : max(0, -offset - 30)
        return min(1.0, 0.4 + magnitude / 100.0)
    }

    private func hintOpacity(for offset: CGFloat, positive: Bool) -> Double {
        let magnitude = positive ? max(0, offset - 30) : max(0, -offset - 30)
        return min(1.0, Double(magnitude) / 60.0)
    }

    private func commitSwipe(right: Bool) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(motionAnimation) {
            dragX = 0
        }
        if right {
            onFavorite?()
        } else {
            onShare?()
        }
    }

    private func springBack() {
        withAnimation(motionAnimation) {
            dragX = 0
        }
    }

    private var motionAnimation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.24)
    }

    private var imageArea: some View {
        GeometryReader { proxy in
            let imageSize = finiteSize(proxy.size)

            placeholderImage
                .frame(
                    width: imageSize.width,
                    height: imageSize.height
                )
                .clipped()
        }
        .aspectRatio(isGridCompact ? 1.0 : 4.0 / 5.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .overlay(alignment: .topLeading) {
            moodBadge
                .padding(isCompact ? 12 : 14)
        }
        .overlay(alignment: .topTrailing) {
            if memory.voicePath?.hasPrefix("slideshows/") == true {
                videoBadge
                    .padding(isCompact ? 12 : 14)
            }
        }
        .overlay(alignment: .center) {
            if memory.voicePath?.hasPrefix("slideshows/") == true {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.26))
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(x: 1.5)
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.55), lineWidth: 0.5)
        }
        .task(id: memory.thumbnailPath) {
            thumbnail = nil
            imageRevealed = false
            guard let thumbnailPath = memory.thumbnailPath else { return }
            let preparedThumbnail = await imagePipeline.preparedImage(forRelativePath: thumbnailPath)
            thumbnail = preparedThumbnail
            withAnimation(MemoryInkMotion.standard(reduceMotion: reduceMotion)) {
                imageRevealed = preparedThumbnail != nil
            }
        }
    }

    /// The photograph, and nothing on top of it.
    ///
    /// Part C removed eight layers that used to sit over every picture: a radial "light leak" on
    /// `.screen`, a mood-tint gradient also on `.screen`, a masked accent wash along the bottom,
    /// three decorative film strips, a white-to-vignette gradient, a blurred lens-flare circle, a
    /// grain canvas, and a white edge stroke. Each was subtle enough to defend on its own; stacked,
    /// they were a filter. Two of them used `.screen`, which *lifts blacks by definition* — against
    /// a near-black ground that greyed out every photo in the app.
    private var placeholderImage: some View {
        ZStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .opacity(imageRevealed || reduceMotion ? 1 : 0)
            } else {
                // A memory without a picture still needs a surface. One flat wash at badge weight
                // — a mark, not a treatment.
                MemoryInkColors.paperWarm
                    .overlay(memory.mood.tint.opacity(0.14))
                    .overlay {
                        Image(systemName: memory.mood.symbolName)
                            .font(.system(size: isCompact ? 22 : 26, weight: .light))
                            .foregroundStyle(memory.mood.tint.opacity(0.55))
                    }
            }
        }
    }

    /// Mood as a dot and a word (C.3). It used to tint the badge's whole background, the date
    /// stamp, and — through `palette`/`accent`/`lightLeak` — the photo itself. Six moods each
    /// colouring large areas meant the app had no consistent colour of its own; now the hue appears
    /// once, small, where it is actually saying something.
    private var moodBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(memory.mood.tint)
                .frame(width: 6, height: 6)

            Text(memory.mood.title.uppercased())
                .font(MemoryInkTypography.badge)
                .kerning(0.6)
                .foregroundStyle(MemoryInkColors.ink.opacity(0.88))
        }
        .padding(.horizontal, isCompact ? 9 : 10)
        .padding(.vertical, isCompact ? 5 : 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(MemoryInkColors.hairline.opacity(0.4), lineWidth: 0.5)
        }
    }

    private var dateStamp: some View {
        VStack(alignment: .center, spacing: -1) {
            Text(memory.timestamp.formatted(.dateTime.day()))
                .font(.system(size: 17, weight: .bold, design: .default))
            Text(memory.timestamp.formatted(.dateTime.month(.abbreviated)).uppercased())
                .font(.system(size: 9, weight: .semibold))
                .kerning(0.5)
        }
        .foregroundStyle(MemoryInkColors.ink)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var favoriteBadge: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(memory.mood.tint)
            .frame(width: 20, height: 20)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(MemoryInkColors.hairline.opacity(0.22), lineWidth: 0.6)
            }
    }

    private var videoBadge: some View {
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
    }

    private var timestampRow: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(MemoryInkColors.hairline.opacity(0.42))
                .frame(width: 24, height: 1)

            Text(memory.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
        }
    }

    private var pendingLabel: some View {
        Text("Writing quietly")
            .font(MemoryInkTypography.timestamp)
            .foregroundStyle(MemoryInkColors.tertiaryInk)
    }

    private func retryControl(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text("Try Again")
                .font(MemoryInkTypography.timestamp.weight(.medium))
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(MemoryInkColors.paper.opacity(0.72))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.7)
                }
        }
        .buttonStyle(.plain)
    }

    private func finiteSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: finiteDimension(size.width),
            height: finiteDimension(size.height)
        )
    }

    private func finiteDimension(_ value: CGFloat, fallback: CGFloat = 0) -> CGFloat {
        guard value.isFinite else {
            return fallback
        }

        return max(value, 0)
    }
}

private struct SilentVideoPreview: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        let player = AVPlayer(url: url)
        player.isMuted = true
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        player.play()
        context.coordinator.player = player
        context.coordinator.layer = layer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            player.pause()
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.layer?.frame = uiView.bounds
    }

    class Coordinator {
        var player: AVPlayer?
        var layer: AVPlayerLayer?

        deinit { player?.pause() }
    }
}

struct TimelineCard_Previews: PreviewProvider {
    static var previews: some View {
        TimelineCard(memory: TimelineMemory.preview) {}
            .environmentObject(ImagePipelineService())
            .padding()
            .background(MemoryInkColors.parchment)
    }
}
