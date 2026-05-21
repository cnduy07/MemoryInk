import SwiftUI

struct RecapView: View {
    @EnvironmentObject private var recapService: RecapService
    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var analyticsService: AnalyticsService
    @State private var isGenerating = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Weekly Reflection")
                    .font(MemoryInkTypography.eyebrow)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
                    .textCase(.uppercase)

                if let recap = recapService.latestRecap {
                    moodDistribution
                    recapCard(recap)
                } else if let errorMessage = recapService.errorMessage {
                    EmptyStateView(
                        message: errorMessage,
                        actionLabel: "Try again",
                        isActionDisabled: isGenerating
                    ) {
                        Task {
                            await generateRecap()
                        }
                    }
                } else {
                    EmptyStateView(
                        message: "Your weekly recap will appear when there's enough to reflect on."
                    )
                }

                if recapService.latestRecap == nil {
                    if isGenerating {
                        LoadingIndicator()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        generateButton
                    }
                }
            }
            .padding(.horizontal, MemoryInkSpacing.screenHorizontal)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(MemoryInkColors.parchment.ignoresSafeArea())
        .navigationTitle("Weekly Recap")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            analyticsService.track(.recapOpened)
        }
    }

    private func recapCard(_ recap: WeeklyRecap) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(MemoryInkColors.amber.opacity(0.55))
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 14) {
                Text("✦")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MemoryInkColors.tertiaryInk.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(recap.recap)
                    .font(MemoryInkTypography.narrative)
                    .foregroundStyle(MemoryInkColors.ink)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Week of \(recap.generatedAt.formatted(.dateTime.month(.wide).day()))")
                    .font(MemoryInkTypography.timestamp)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
            }
            .padding(MemoryInkSpacing.cardPadding)
        }
        .background(
            LinearGradient(
                colors: [MemoryInkColors.paper, MemoryInkColors.paperWarm],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.22), lineWidth: 0.7)
        }
    }

    private var moodDistribution: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This week's mood")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 8), spacing: 4)], alignment: .leading, spacing: 4) {
                ForEach(currentWeekEntries) { entry in
                    Circle()
                        .fill(entry.mood.tint)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 2)
    }

    private var currentWeekEntries: [JournalEntry] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return repository.entriesSince(weekAgo)
    }

    private var generateButton: some View {
        Button {
            Task {
                await generateRecap()
            }
        } label: {
            Text("Reflect on this week")
                .font(MemoryInkTypography.narrativeCompact.weight(.medium))
                .foregroundStyle(MemoryInkColors.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(MemoryInkColors.paper.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func generateRecap() async {
        guard !isGenerating else { return }

        isGenerating = true
        await recapService.generateWeeklyRecapIfPossible()
        isGenerating = false
    }
}
