import SwiftUI

struct MoodIntroView: View {
    let onComplete: () -> Void

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

            VStack(alignment: .leading, spacing: 16) {
                Text("Choose the feeling.")
                    .font(MemoryInkTypography.title)
                    .foregroundStyle(MemoryInkColors.ink)

                Text("Peaceful, nostalgic, happy, proud, sad, or reflective. Your mood guides the tone without making the memory feel noisy.")
                    .font(MemoryInkTypography.narrative)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .lineSpacing(7)

                Spacer()

                Button {
                    onComplete()
                } label: {
                    Text("Get started")
                        .font(MemoryInkTypography.narrativeCompact.weight(.medium))
                        .foregroundStyle(MemoryInkColors.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MemoryInkColors.paper.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }
}
