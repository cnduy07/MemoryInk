import SwiftUI

struct OnThisDayView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var service: OnThisDayService
    @EnvironmentObject private var analyticsService: AnalyticsService

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("On This Day")
                    .font(MemoryInkTypography.eyebrow)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
                    .textCase(.uppercase)

                if service.entries.isEmpty {
                    EmptyStateView(message: "Nothing from this day yet — but there will be.")
                } else {
                    ForEach(service.entries) { entry in
                        entryCard(entry)
                    }
                }
            }
            .padding(.horizontal, MemoryInkSpacing.screenHorizontal)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(MemoryInkColors.parchment.ignoresSafeArea())
        .navigationTitle("On This Day")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            analyticsService.track(.onThisDayOpened)
            service.refresh()
        }
    }

    private func entryCard(_ entry: JournalEntry) -> some View {
        Button {
            router.path.append(.memoryDetail(id: entry.id))
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(entry.mood.tint.opacity(0.50))
                    .frame(width: 2)

                VStack(alignment: .leading, spacing: 12) {
                    Text(yearsAgoLabel(for: entry.createdAt))
                        .font(MemoryInkTypography.badge)
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(MemoryInkColors.sunlit.opacity(0.18))
                        .clipShape(Capsule())

                    moodBadge(for: entry.mood)

                    Text(entry.aiNarrative?.isEmpty == false ? entry.aiNarrative ?? "" : "A memory from this day.")
                        .font(MemoryInkTypography.narrativeCompact)
                        .foregroundStyle(MemoryInkColors.ink)
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(MemoryInkColors.tertiaryInk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
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
            .contentShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func moodBadge(for mood: MoodType) -> some View {
        Text(mood.title)
            .font(MemoryInkTypography.badge)
            .foregroundStyle(MemoryInkColors.ink.opacity(0.78))
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .background(mood.tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func yearsAgoLabel(for date: Date) -> String {
        let years = Calendar.current.dateComponents([.year], from: date, to: .now).year ?? 0
        return years == 1 ? "Last year" : "\(years) years ago"
    }
}
