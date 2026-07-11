import SwiftUI
import UIKit
import AVFoundation

struct TimelineCard: View {
    @EnvironmentObject private var imagePipeline: ImagePipelineService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let memory: TimelineMemory
    let namespace: Namespace.ID?
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
        namespace: Namespace.ID? = nil,
        isExpanded: Bool = false,
        isCompact: Bool = false,
        isGridCompact: Bool = false,
        retryAction: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onFavorite: (() -> Void)? = nil,
        onTap: @escaping () -> Void
    ) {
        self.memory = memory
        self.namespace = namespace
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
                        .foregroundStyle(.white)
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
                    DragGesture(minimumDistance: 20, coordinateSpace: .global)
                        .onChanged { value in
                            let horizontal = abs(value.translation.width)
                            let vertical = abs(value.translation.height)
                            guard horizontal > vertical * 1.2 else { return }
                            dragX = value.translation.width
                        }
                        .onEnded { value in
                            let horizontal = abs(value.translation.width)
                            let vertical = abs(value.translation.height)
                            guard horizontal > vertical else {
                                springBack()
                                return
                            }
                            let projected = value.translation.width + value.predictedEndTranslation.width * 0.22
                            if projected > swipeThreshold {
                                commitSwipe(right: true)
                            } else if projected < -swipeThreshold {
                                commitSwipe(right: false)
                            } else {
                                springBack()
                            }
                        },
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
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.46),
                            MemoryInkColors.hairline.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
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

    private var placeholderImage: some View {
        ZStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .opacity(imageRevealed || reduceMotion ? 1 : 0.72)
                    .scaleEffect(imageRevealed || reduceMotion ? 1 : 1.035)
            } else {
                LinearGradient(
                    colors: memory.palette,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            RadialGradient(
                colors: [
                    memory.lightLeak.opacity(0.68),
                    memory.lightLeak.opacity(0.0)
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 190
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [
                    memory.mood.tint.opacity(0.12),
                    Color.clear,
                    memory.mood.secondaryTint.opacity(0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                LinearGradient(
                    colors: [
                        memory.accent.opacity(0.62),
                        memory.accent.opacity(0.16)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: isExpanded ? 108 : (isCompact ? 78 : 92))
                .mask(
                    RoundedRectangle(cornerRadius: 56, style: .continuous)
                        .offset(y: 46)
                )
            }

            VStack {
                Spacer()
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(index == 1 ? 0.22 : 0.13))
                            .frame(width: index == 1 ? 56 : 36, height: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, isCompact ? 18 : 22)
            }

            LinearGradient(
                colors: [
                    Color.white.opacity(0.16),
                    Color.clear,
                    MemoryInkColors.vignette.opacity(0.32)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 132, height: 132)
                        .blur(radius: 18)
                        .offset(x: 38, y: 28)
                }
            }

            subtleGrain
        }
    }

    private var moodBadge: some View {
        Text(memory.mood.title)
            .font(MemoryInkTypography.badge)
            .foregroundStyle(MemoryInkColors.ink.opacity(0.76))
            .padding(.horizontal, isCompact ? 10 : 11)
            .padding(.vertical, isCompact ? 5 : 6)
            .background(.ultraThinMaterial)
            .background(memory.mood.tint.opacity(0.28))
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.28), lineWidth: 0.6)
            }
            .clipShape(Capsule())
    }

    private var dateStamp: some View {
        VStack(alignment: .center, spacing: -1) {
            Text(memory.timestamp.formatted(.dateTime.day()))
                .font(.system(size: 17, weight: .bold, design: .default))
            Text(memory.timestamp.formatted(.dateTime.month(.abbreviated)).uppercased())
                .font(.system(size: 9, weight: .semibold))
                .kerning(0.5)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial)
        .background(memory.mood.tint.opacity(0.22))
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

    private var subtleGrain: some View {
        Canvas { context, size in
            let safeWidth = finiteDimension(size.width)
            let safeHeight = finiteDimension(size.height)

            guard safeWidth > 0, safeHeight > 0 else {
                return
            }

            let spacing: CGFloat = 11
            var x: CGFloat = 4

            while x < safeWidth {
                var y: CGFloat = 5

                while y < safeHeight {
                    let opacity = ((Int(x + y) % 5) == 0) ? 0.030 : 0.016
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(Color.white.opacity(opacity))
                    )
                    y += spacing
                }

                x += spacing
            }
        }
        .allowsHitTesting(false)
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
