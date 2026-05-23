import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        TabView {
            welcome
            PrivacyScreenView()
            MoodIntroView(onComplete: onComplete)
        }
        .tabViewStyle(.page)
        .background(MemoryInkColors.parchment.ignoresSafeArea())
    }

    private var welcome: some View {
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

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                HStack(spacing: 8) {
                    ForEach(MoodType.allCases) { mood in
                        Circle()
                            .fill(mood.tint.opacity(0.72))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.bottom, 28)

                Text("MemoryInk")
                    .font(.system(size: 44, weight: .semibold, design: .default))
                    .foregroundStyle(MemoryInkColors.ink)

                Text("Small moments,\nheld quietly.")
                    .font(MemoryInkTypography.narrative)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .lineSpacing(7)
                    .padding(.top, 12)

                Spacer()

                HStack(spacing: 6) {
                    Text("Swipe to continue")
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(MemoryInkColors.tertiaryInk)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MemoryInkColors.tertiaryInk)
                }
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }
}
