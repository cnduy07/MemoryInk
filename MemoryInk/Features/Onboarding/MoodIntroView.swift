import SwiftUI

struct MoodIntroView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose the feeling.")
                .font(MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text("Peaceful, nostalgic, happy, proud, sad, or reflective. Your mood guides the tone without making the memory feel noisy.")
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .lineSpacing(7)
        }
        .padding(28)
    }
}
