import SwiftUI

struct OnboardingView: View {
    var body: some View {
        TabView {
            welcome
            PrivacyScreenView()
            MoodIntroView()
        }
        .tabViewStyle(.page)
        .background(MemoryInkColors.parchment.ignoresSafeArea())
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MemoryInk")
                .font(MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text("A private place for small moments to become memories.")
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .lineSpacing(7)
        }
        .padding(28)
    }
}
