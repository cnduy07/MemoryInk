import SwiftUI
import UIKit

struct TimelineCard: View {
    let memory: TimelineMemory
    let namespace: Namespace.ID?
    let isExpanded: Bool
    let isCompact: Bool
    let isGridCompact: Bool
    let retryAction: (() -> Void)?
    let onTap: () -> Void

    init(
        memory: TimelineMemory,
        namespace: Namespace.ID? = nil,
        isExpanded: Bool = false,
        isCompact: Bool = false,
        isGridCompact: Bool = false,
        retryAction: (() -> Void)? = nil,
        onTap: @escaping () -> Void
    ) {
        self.memory = memory
        self.namespace = namespace
        self.isExpanded = isExpanded
        self.isCompact = isCompact
        self.isGridCompact = isGridCompact
        self.retryAction = retryAction
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
            .overlay(alignment: .bottomTrailing) {
                if memory.isFavorite {
                    favoriteBadge
                        .padding(10)
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
    }

    private var placeholderImage: some View {
        ZStack {
            if let thumbnailPath = memory.thumbnailPath,
               let thumbnail = ImagePipelineService.image(forRelativePath: thumbnailPath) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
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
            .background(memory.mood.tint.opacity(0.12))
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.28), lineWidth: 0.6)
            }
            .clipShape(Capsule())
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

struct TimelineCard_Previews: PreviewProvider {
    static var previews: some View {
        TimelineCard(memory: TimelineMemory.preview) {}
            .padding()
            .background(MemoryInkColors.parchment)
    }
}
