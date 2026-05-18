import SwiftUI

struct PrivacyScreenView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your photos stay on your device.")
                .font(MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text("MemoryInk only sends lightweight text descriptions to generate narratives. We never upload your original photos.")
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .lineSpacing(7)
        }
        .padding(28)
    }
}
