import SwiftUI

/// Reusable animated horizontal bar chart: one row per mood, a spring-animated
/// proportional bar, and a count. Extracted from Recap's mood-distribution chart
/// so other screens (e.g. Yearly Review) can show the same "how much of each mood"
/// breakdown without re-implementing the bar/animation math.
///
/// Not merged with `EmotionGraphView` — that's a trend-over-time line chart (mood
/// valence across entries in chronological order), a genuinely different chart type
/// with different data and different math. Forcing both into one component wouldn't
/// actually share meaningful code, just make either use case harder to read.
struct MemoryInkMoodDistributionChart: View {
    struct Item {
        let mood: MoodType
        let count: Int
    }

    let items: [Item]
    let total: Int
    /// Drives the reveal animation — bars grow from zero width once this becomes true.
    var isVisible: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.element.mood) { index, item in
                row(mood: item.mood, count: item.count, index: index)
            }
        }
    }

    private func row(mood: MoodType, count: Int, index: Int) -> some View {
        let fraction = Double(count) / Double(max(total, 1))

        return HStack(spacing: 10) {
            Text(mood.title)
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .frame(width: 80, alignment: .trailing)

            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 4)
                    .fill(mood.tint)
                    .frame(
                        width: max(8, proxy.size.width * fraction) * (isVisible ? 1.0 : 0.0),
                        height: 8
                    )
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.75)
                            .delay(Double(index) * 0.08),
                        value: isVisible
                    )
            }
            .frame(height: 8)

            Text("\(count)")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
        }
    }
}
