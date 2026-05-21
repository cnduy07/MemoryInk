import SwiftUI

struct OnThisDayView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var service: OnThisDayService
    @EnvironmentObject private var analyticsService: AnalyticsService

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                heroHeader
                    .padding(.horizontal, 22)

                if service.entries.isEmpty {
                    EmptyStateView(message: "Nothing from this day yet — but there will be.")
                        .padding(.horizontal, 22)
                } else {
                    ForEach(service.entries) { entry in
                        entryCard(entry)
                            .padding(.horizontal, 22)
                    }
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(MemoryInkColors.parchment.ignoresSafeArea())
        .navigationTitle("On This Day")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            analyticsService.track(.onThisDayOpened)
            service.refresh()
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ON THIS DAY")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)

            Spacer()

            Text(Date().formatted(.dateTime.month(.wide).day()))
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(MemoryInkColors.ink)

            Spacer()

            Text(memoryCountLabel)
                .font(MemoryInkTypography.badge)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .background(
            LinearGradient(
                colors: [
                    MemoryInkColors.rosewood.opacity(0.55),
                    MemoryInkColors.rosewood.opacity(0.18),
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
        .shadow(color: MemoryInkColors.rosewood.opacity(0.16), radius: 22, x: 0, y: 10)
    }

    private func entryCard(_ entry: JournalEntry) -> some View {
        Button {
            router.path.append(.memoryDetail(id: entry.id))
        } label: {
            ZStack(alignment: .bottom) {
                cardBackground(for: entry)

                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack {
                    HStack {
                        Text(yearsAgoLabel(for: entry.createdAt))
                            .font(MemoryInkTypography.badge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(MemoryInkColors.rosewood.opacity(0.70))
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())

                        Spacer()
                    }

                    Spacer()
                }
                .padding(14)

                bottomOverlay(for: entry)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 12)
            .contentShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func cardBackground(for entry: JournalEntry) -> some View {
        if let img = ImagePipelineService.image(forRelativePath: entry.thumbnailPath) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            LinearGradient(
                colors: [entry.mood.tint, entry.mood.tint.opacity(0.40)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }

    private func bottomOverlay(for entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.mood.title)
                .font(MemoryInkTypography.badge)
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .background(entry.mood.tint.opacity(0.30))
                .clipShape(Capsule())

            if let narrative = entry.aiNarrative, !narrative.isEmpty {
                Text(narrative)
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(.white.opacity(0.90))
                    .lineSpacing(5)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(entry.createdAt.formatted(date: .long, time: .omitted))
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
    }

    private var memoryCountLabel: String {
        if service.entries.isEmpty {
            return "Nothing yet"
        }

        return "\(service.entries.count) \(service.entries.count == 1 ? "memory" : "memories")"
    }

    private func yearsAgoLabel(for date: Date) -> String {
        let years = Calendar.current.dateComponents([.year], from: date, to: .now).year ?? 0
        if years == 0 { return "This year" }
        if years == 1 { return "1 year ago" }
        return "\(years) years ago"
    }
}
