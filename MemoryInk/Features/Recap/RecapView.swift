import SwiftUI

struct RecapView: View {
    @EnvironmentObject private var recapService: RecapService
    @EnvironmentObject private var analyticsService: AnalyticsService

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Weekly recap")
                .font(MemoryInkTypography.subtitle)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            Text(recapService.latestRecap?.recap ?? recapService.errorMessage ?? "Your weekly recap will appear here when there is enough to reflect on.")
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.ink)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(MemoryInkColors.paper.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .task {
            analyticsService.track(.recapOpened)
            await recapService.generateWeeklyRecapIfPossible()
        }
    }
}
