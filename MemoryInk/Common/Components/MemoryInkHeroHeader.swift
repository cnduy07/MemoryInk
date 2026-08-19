import SwiftUI

/// Shared "hero banner" header: a tall, mood/tint-tinted gradient card with an eyebrow
/// label, a title area, and a footer row (typically capsule badges).
///
/// Extracted from near-duplicate implementations that used to live independently in
/// RecapView and OnThisDayView (same skeleton, slightly different opacity/shadow values).
/// New screens that need a hero moment should use this instead of hand-rolling another copy.
struct MemoryInkHeroHeader<Title: View, Footer: View>: View {
    let eyebrow: String
    let tint: Color
    var height: CGFloat = 150

    @ViewBuilder var title: () -> Title
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(eyebrow)
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)

            Spacer()

            title()

            Spacer()

            footer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(
            LinearGradient(
                colors: [
                    tint.opacity(0.60),
                    tint.opacity(0.18),
                    MemoryInkColors.parchment
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.18), lineWidth: 0.7)
        }
        .shadow(color: tint.opacity(0.18), radius: 24, x: 0, y: 12)
    }
}
