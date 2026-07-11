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
        .background(MemoryInkAmbientBackdrop(mood: .nostalgic).ignoresSafeArea())
    }

    private var welcome: some View {
        ZStack {
            MemoryInkAmbientBackdrop(mood: .nostalgic, intensity: 1.12)
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                HStack(spacing: 8) {
                    ForEach(MoodType.allCases) { mood in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: mood.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 12, height: 12)
                            .shadow(color: mood.tint.opacity(0.28), radius: 5)
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
            .memoryInkEntrance(delay: 0.04)
        }
    }
}
