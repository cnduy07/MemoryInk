import SwiftUI

struct MoodIntroView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            MemoryInkAmbientBackdrop(mood: .reflective, intensity: 1.08)
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Choose the feeling.")
                    .font(MemoryInkTypography.title)
                    .foregroundStyle(MemoryInkColors.ink)

                Text("Peaceful, nostalgic, happy, proud, sad, or reflective. Your mood guides the tone without making the memory feel noisy.")
                    .font(MemoryInkTypography.narrative)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .lineSpacing(7)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                    spacing: 10
                ) {
                    ForEach(MoodType.allCases) { mood in
                        VStack(spacing: 7) {
                            Image(systemName: mood.symbolName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MemoryInkColors.onAccent)
                                .frame(width: 38, height: 38)
                                .background(
                                    LinearGradient(
                                        colors: mood.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: mood.tint.opacity(0.20), radius: 7, x: 0, y: 4)

                            Text(mood.title)
                                .font(MemoryInkTypography.timestamp.weight(.medium))
                                .foregroundStyle(MemoryInkColors.secondaryInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 76)
                        .background(.ultraThinMaterial)
                        .background(mood.tint.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.top, 10)

                Spacer()

                Button {
                    onComplete()
                } label: {
                    Text("Get started")
                        .font(MemoryInkTypography.narrativeCompact.weight(.medium))
                        .foregroundStyle(MemoryInkColors.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [MemoryInkColors.orchid, MemoryInkColors.twilight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: MemoryInkColors.orchid.opacity(0.24), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(MemoryInkPressStyle())
            }
            .padding(28)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .memoryInkEntrance(delay: 0.05)
        }
    }
}
