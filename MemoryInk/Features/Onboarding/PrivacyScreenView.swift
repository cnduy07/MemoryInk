import SwiftUI

struct PrivacyScreenView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    MemoryInkColors.parchment,
                    MemoryInkColors.paperWarm,
                    MemoryInkColors.parchmentDeep
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Text("Your photos stay on your device.")
                    .font(MemoryInkTypography.title)
                    .foregroundStyle(MemoryInkColors.ink)

                VStack(alignment: .leading, spacing: 24) {
                    privacyRow(
                        icon: "lock.shield.fill",
                        title: "Your photos stay on device.",
                        subtitle: "MemoryInk never uploads original photos."
                    )

                    privacyRow(
                        icon: "eye.slash.fill",
                        title: "Only lightweight descriptions leave.",
                        subtitle: "Scene labels and mood — never the image itself."
                    )

                    privacyRow(
                        icon: "sparkles",
                        title: "AI works from shadows, not the source.",
                        subtitle: "Narratives are generated from metadata only."
                    )
                }
                .padding(MemoryInkSpacing.cardPadding)
                .background(MemoryInkColors.paper.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(MemoryInkColors.hairline.opacity(0.22), lineWidth: 0.7)
                }
            }
            .padding(28)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    private func privacyRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .frame(width: 36, height: 36)
                .background(MemoryInkColors.parchmentDeep.opacity(0.60))
                .clipShape(Circle())

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
