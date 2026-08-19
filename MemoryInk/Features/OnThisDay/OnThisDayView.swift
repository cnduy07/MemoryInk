import SwiftUI

struct OnThisDayView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var service: OnThisDayService
    @EnvironmentObject private var analyticsService: AnalyticsService

    var body: some View {
        ScrollViewReader { scroll in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    heroHeader
                        .padding(.horizontal, 22)
                        .memoryInkEntrance()

                    if service.years.isEmpty {
                        EmptyStateView(message: "Nothing from this day yet — but there will be.")
                            .padding(.horizontal, 22)
                            .memoryInkEntrance(delay: 0.06)
                    } else {
                        if service.years.count > 1 {
                            yearComparisonStrip(scroll: scroll)
                                .memoryInkEntrance(delay: 0.06)
                        }

                        ForEach(Array(service.years.enumerated()), id: \.element.id) { index, year in
                            yearSection(year)
                                .id(year.id)
                                .memoryInkEntrance(delay: 0.10 + Double(index) * 0.05)
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .background(MemoryInkAmbientBackdrop(mood: service.entries.first?.mood, intensity: 1.0).ignoresSafeArea())
        .navigationTitle("On This Day")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            analyticsService.track(.onThisDayOpened)
            service.refresh()
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        MemoryInkHeroHeader(eyebrow: "ON THIS DAY", tint: MemoryInkColors.rosewood, height: 140) {
            Text(Date().formatted(.dateTime.month(.wide).day()))
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(MemoryInkColors.ink)
        } footer: {
            HStack(spacing: 8) {
                chip(memoryCountLabel)

                if let journeyLabel {
                    chip(journeyLabel)
                }
            }
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(MemoryInkTypography.badge)
            .foregroundStyle(MemoryInkColors.secondaryInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Year comparison

    /// The same date, side by side across every year it appears in. Tapping a year
    /// scrolls down to that year's memories.
    private func yearComparisonStrip(scroll: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACROSS THE YEARS")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .padding(.horizontal, 22)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(service.years.enumerated()), id: \.element.id) { index, year in
                        Button {
                            MemoryInkHaptics.light()
                            withAnimation(.easeInOut(duration: 0.28)) {
                                scroll.scrollTo(year.id, anchor: .top)
                            }
                        } label: {
                            yearTile(year)
                        }
                        .buttonStyle(MemoryInkPressStyle())
                        .padding(.leading, index == 0 ? 22 : 0)
                        .padding(.trailing, index == service.years.count - 1 ? 22 : 0)
                    }
                }
            }
        }
    }

    private func yearTile(_ year: OnThisDayYear) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                tileBackground(for: year)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(year.year))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(year.yearsAgoLabel)
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(10)
            }
            .frame(width: 116, height: 148)
        }
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.radiusSmall, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.radiusSmall, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
        }
        .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 6)
    }

    @ViewBuilder
    private func tileBackground(for year: OnThisDayYear) -> some View {
        if let path = year.coverEntry?.thumbnailPath,
           let image = ImagePipelineService.image(forRelativePath: path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 116, height: 148)
                .clipped()
        } else {
            let tint = year.dominantMood?.tint ?? MemoryInkColors.rosewood
            LinearGradient(
                colors: [tint, tint.opacity(0.40)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Year sections

    private func yearSection(_ year: OnThisDayYear) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            yearSectionHeader(year)
                .padding(.horizontal, 22)

            ForEach(year.entries) { entry in
                entryCard(entry, year: year)
                    .padding(.horizontal, 22)
            }
        }
    }

    private func yearSectionHeader(_ year: OnThisDayYear) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(year.dominantMood?.tint ?? MemoryInkColors.rosewood)
                .frame(width: 3, height: 18)

            Text(String(year.year))
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(MemoryInkColors.ink)

            Text(year.yearsAgoLabel)
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)

            Spacer()

            Text(countLabel(year.entries.count))
                .font(MemoryInkTypography.badge)
                .foregroundStyle(MemoryInkColors.secondaryInk)
        }
    }

    private func entryCard(_ entry: JournalEntry, year: OnThisDayYear) -> some View {
        Button {
            MemoryInkHaptics.light()
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
                        Text(year.yearsAgoLabel)
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
        .buttonStyle(MemoryInkPressStyle())
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

    // MARK: - Labels

    private var memoryCountLabel: String {
        service.entries.isEmpty ? "Nothing yet" : countLabel(service.entries.count)
    }

    private func countLabel(_ count: Int) -> String {
        "\(count) \(count == 1 ? "memory" : "memories")"
    }

    private var journeyLabel: String? {
        guard let day = service.journeyDayNumber else { return nil }
        return "Day \(day)"
    }
}
