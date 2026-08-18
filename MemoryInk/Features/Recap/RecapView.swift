import SwiftUI

struct RecapView: View {
    @EnvironmentObject private var recapService: RecapService
    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var analyticsService: AnalyticsService
    @EnvironmentObject private var router: AppRouter
    @State private var isGenerating = false
    @State private var barsVisible = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                heroHeader
                    .padding(.horizontal, 22)

                if !weekEntries.isEmpty {
                    memoryStrip
                }

                if !weekEntries.isEmpty {
                    moodDistributionBars
                }

                if let recap = recapService.latestRecap {
                    recapCard(recap)
                } else if isGenerating {
                    loadingCard
                        .padding(.horizontal, 22)
                } else if let error = recapService.errorMessage {
                    EmptyStateView(
                        message: error,
                        actionLabel: "Try again",
                        isActionDisabled: false
                    ) {
                        Task { await generateRecap() }
                    }
                    .padding(.horizontal, 22)
                } else {
                    EmptyStateView(
                        message: "Your weekly recap will appear when there's enough to reflect on."
                    )
                    .padding(.horizontal, 22)
                }

                if recapService.latestRecap == nil && !isGenerating {
                    generateButton
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(MemoryInkAmbientBackdrop(mood: dominantMood, intensity: 1.0).ignoresSafeArea())
        .navigationTitle("Weekly Recap")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                barsVisible = true
            }
        }
        .task {
            analyticsService.track(.recapOpened)
        }
    }

    private var heroHeader: some View {
        MemoryInkHeroHeader(eyebrow: "WEEKLY REFLECTION", tint: dominantMoodTint, height: 160) {
            Text(weekRangeLabel)
                .font(MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)
                .frame(maxWidth: .infinity, alignment: .center)
        } footer: {
            HStack {
                Text("\(weekEntries.count) memories")
                    .font(MemoryInkTypography.badge)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Text(dominantMood.title)
                    .font(MemoryInkTypography.badge)
                    .foregroundStyle(MemoryInkColors.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(dominantMood.tint.opacity(0.30), in: Capsule())
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    private var memoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(memoryStripEntries.enumerated()), id: \.element.id) { index, entry in
                    memoryTile(for: entry)
                        .padding(.leading, index == 0 ? 22 : 0)
                        .padding(.trailing, index == memoryStripEntries.count - 1 ? 22 : 0)
                }
            }
        }
    }

    private func memoryTile(for entry: JournalEntry) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let image = ImagePipelineService.image(forRelativePath: entry.thumbnailPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [entry.mood.tint, entry.mood.tint.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(entry.createdAt.formatted(.dateTime.day()))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(6)
        }
        .frame(width: 80, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            router.path.append(.memoryViewer(entryId: entry.id))
        }
    }

    private var moodDistributionBars: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THIS WEEK'S MOOD")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)

            MemoryInkMoodDistributionChart(
                items: moodCounts.map { MemoryInkMoodDistributionChart.Item(mood: $0.mood, count: $0.count) },
                total: weekEntries.count,
                isVisible: barsVisible
            )
        }
        .padding(.horizontal, 22)
    }

    private func recapCard(_ recap: WeeklyRecap) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [MemoryInkColors.paper, MemoryInkColors.paperWarm],
                startPoint: .top,
                endPoint: .bottomTrailing
            )

            Text("✦")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(MemoryInkColors.tertiaryInk.opacity(0.50))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(18)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MemoryInkColors.amber)
                        .frame(width: 3, height: 18)

                    Text("Your Week")
                        .font(MemoryInkTypography.eyebrow)
                        .foregroundStyle(MemoryInkColors.tertiaryInk)
                }

                Text(recap.recap)
                    .font(MemoryInkTypography.narrative)
                    .foregroundStyle(MemoryInkColors.ink)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Week of \(recap.generatedAt.formatted(.dateTime.month(.wide).day()))")
                    .font(MemoryInkTypography.timestamp)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)

                if recap.cached {
                    Text("From earlier this week")
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(MemoryInkColors.tertiaryInk.opacity(0.60))
                }
            }
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.22), lineWidth: 0.7)
        }
        .shadow(color: MemoryInkColors.amber.opacity(0.10), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 22)
    }

    private var loadingCard: some View {
        RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous)
            .fill(MemoryInkColors.paper.opacity(0.60))
            .frame(height: 160)
            .overlay {
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(MemoryInkColors.amber)

                    Text("Writing your reflection...")
                        .font(MemoryInkTypography.narrativeCompact)
                        .foregroundStyle(MemoryInkColors.tertiaryInk)
                }
            }
    }

    private var generateButton: some View {
        Button {
            MemoryInkHaptics.medium()
            Task { await generateRecap() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))

                Text("Reflect on this week")
                    .font(MemoryInkTypography.narrativeCompact.weight(.semibold))
            }
            .foregroundStyle(MemoryInkColors.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [MemoryInkColors.amber.opacity(0.18), MemoryInkColors.amber.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MemoryInkColors.amber.opacity(0.35), lineWidth: 0.8)
            }
        }
        .buttonStyle(MemoryInkPressStyle())
        .padding(.horizontal, 22)
    }

    private var weekEntries: [JournalEntry] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return repository.entriesSince(weekAgo)
    }

    private var dominantMood: MoodType {
        let counts = Dictionary(grouping: weekEntries, by: \.mood).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? .peaceful
    }

    private var moodCounts: [(mood: MoodType, count: Int)] {
        let counts = Dictionary(grouping: weekEntries, by: \.mood).mapValues(\.count)
        return MoodType.allCases
            .compactMap { mood in
                let count = counts[mood, default: 0]
                return count > 0 ? (mood: mood, count: count) : nil
            }
            .sorted { $0.count > $1.count }
    }

    private var weekRangeLabel: String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let start = weekAgo.formatted(.dateTime.month(.wide).day())
        let end = Date().formatted(.dateTime.month(.wide).day())
        return "\(start) – \(end)"
    }

    private var dominantMoodTint: Color {
        weekEntries.isEmpty ? MemoryInkColors.secondaryInk : dominantMood.tint
    }

    private var memoryStripEntries: [JournalEntry] {
        Array(weekEntries.prefix(7))
    }

    private func generateRecap() async {
        guard !isGenerating else { return }

        isGenerating = true
        await recapService.generateWeeklyRecapIfPossible()
        isGenerating = false
    }
}
