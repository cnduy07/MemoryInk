import SwiftUI

struct OnThisDayView: View {
    @EnvironmentObject private var service: OnThisDayService
    @EnvironmentObject private var analyticsService: AnalyticsService

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("On this day")
                .font(MemoryInkTypography.subtitle)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            if service.entries.isEmpty {
                Text("No memories from this day yet.")
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
            } else {
                ForEach(service.entries) { entry in
                    Text(entry.aiNarrative ?? "A memory from this day is waiting quietly.")
                        .font(MemoryInkTypography.narrativeCompact)
                        .foregroundStyle(MemoryInkColors.ink)
                }
            }
        }
        .padding(20)
        .background(MemoryInkColors.paper.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .onAppear {
            analyticsService.track(.onThisDayOpened)
            service.refresh()
        }
    }
}
