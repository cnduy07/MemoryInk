import SwiftUI

struct PrivacyScreenView: View {
    var body: some View {
        ZStack {
            MemoryInkAmbientBackdrop(mood: .peaceful, intensity: 1.0)
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Text("Your photos stay on your device.")
                    .font(MemoryInkTypography.title)
                    .foregroundStyle(MemoryInkColors.ink)

                VStack(alignment: .leading, spacing: 24) {
                    privacyRow(
                        icon: "lock.shield.fill",
                        tint: MemoryInkColors.teal,
                        title: "Your photos stay on device.",
                        subtitle: "MemoryInk never uploads original photos."
                    )

                    privacyRow(
                        icon: "eye.slash.fill",
                        tint: MemoryInkColors.ocean,
                        title: "Only lightweight descriptions leave.",
                        subtitle: "Scene labels and mood — never the image itself."
                    )

                    privacyRow(
                        icon: "sparkles",
                        tint: MemoryInkColors.orchid,
                        title: "AI works from shadows, not the source.",
                        subtitle: "Narratives are generated from metadata only."
                    )
                }
                .padding(MemoryInkSpacing.cardPadding)
                .background(.ultraThinMaterial)
                .background(MemoryInkColors.paper.opacity(0.68))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(MemoryInkColors.hairline.opacity(0.22), lineWidth: 0.7)
                }
            }
            .padding(28)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .memoryInkEntrance(delay: 0.05)
        }
    }

    private func privacyRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.60)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: tint.opacity(0.20), radius: 7, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(MemoryInkTypography.subtitle.weight(.medium))
                    .foregroundStyle(MemoryInkColors.ink)

                Text(subtitle)
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
