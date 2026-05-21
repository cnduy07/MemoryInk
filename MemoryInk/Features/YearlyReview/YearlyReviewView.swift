import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct YearlyReviewView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var imagePipeline: ImagePipelineService
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var yearlyReviewService: YearlyReviewService
    @State private var shareItem: YearlyReviewShareImage?
    @State private var sharePreviewImage: UIImage?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                collage

                if subscriptionManager.hasPremiumEntitlement {
                    premiumContent
                } else {
                    upgradePrompt
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 34)
        }
        .background(background)
        .navigationTitle("Year in Memories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                shareToolbarItem
            }
        }
        .task {
            if subscriptionManager.hasPremiumEntitlement {
                await yearlyReviewService.generateIfPossible()
            }
        }
    }

    @ViewBuilder
    private var premiumContent: some View {
        if let review = yearlyReviewService.review {
            reviewSummary(review)
        } else if yearlyReviewService.isGenerating {
            VStack(spacing: 14) {
                LoadingIndicator()

                Text("Gathering your year quietly.")
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 42)
        } else {
            VStack(alignment: .leading, spacing: 18) {
                Text(yearlyReviewService.errorMessage ?? "Your year in memories will appear when there is enough to reflect on.")
                    .font(MemoryInkTypography.narrative)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .lineSpacing(7)

                Button {
                    Task {
                        await yearlyReviewService.generateIfPossible()
                    }
                } label: {
                    Text("Try again")
                        .font(MemoryInkTypography.timestamp.weight(.medium))
                        .foregroundStyle(MemoryInkColors.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(MemoryInkColors.paper.opacity(0.82))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .background(MemoryInkColors.paper.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        }
    }

    private func reviewSummary(_ review: YearlyReview) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(yearlyReviewService.currentYear)")
                    .font(MemoryInkTypography.eyebrow)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
                    .textCase(.uppercase)

                Text("Your \(review.entryCount) Memories")
                    .font(MemoryInkTypography.title)
                    .foregroundStyle(MemoryInkColors.ink)
            }

            narrativeCard(review.narrative)
        }
    }

    private var upgradePrompt: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MemoryInk+")
                .font(MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text("Your year in memories is a premium reflection built from your local memory metadata.")
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .lineSpacing(7)

            Button {
                router.path.append(.subscriptionPreview)
            } label: {
                Text("View MemoryInk+")
                    .font(MemoryInkTypography.timestamp.weight(.medium))
                    .foregroundStyle(MemoryInkColors.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(MemoryInkColors.paper.opacity(0.86))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(MemoryInkColors.paper.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.8)
        }
    }

    private var collage: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
            spacing: 8
        ) {
            ForEach(0..<9, id: \.self) { index in
                collageCell(at: index)
            }
        }
    }

    @ViewBuilder
    private func collageCell(at index: Int) -> some View {
        let paths = yearlyReviewService.review?.thumbnailPaths ?? Array(repository.entriesSince(oneYearAgo).map(\.thumbnailPath).prefix(9))
        let moods = repository.entriesSince(oneYearAgo).map(\.mood)

        ZStack {
            if paths.indices.contains(index),
               let image = imagePipeline.image(forRelativePath: paths[index]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                moodGradient(moods.indices.contains(index) ? moods[index] : nil)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func narrativeCard(_ narrative: String) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(MemoryInkColors.amber.opacity(0.78))
                .frame(width: 4)

            Text(narrative)
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.ink)
                .lineSpacing(9)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [
                    MemoryInkColors.paper.opacity(0.92),
                    MemoryInkColors.paperWarm.opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.8)
        }
    }

    @ViewBuilder
    private var shareToolbarItem: some View {
        if let shareItem, let sharePreviewImage {
            ShareLink(
                item: shareItem,
                preview: SharePreview("Your Year in Memories", image: Image(uiImage: sharePreviewImage))
            ) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(MemoryInkColors.secondaryInk)
            }
        } else {
            Button {
                prepareShareImage()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(MemoryInkColors.secondaryInk)
            }
            .disabled(yearlyReviewService.review == nil)
        }
    }

    private func prepareShareImage() {
        guard let image = renderShareImage(),
              let data = image.pngData() else {
            return
        }

        sharePreviewImage = image
        shareItem = YearlyReviewShareImage(data: data)
    }

    private func renderShareImage() -> UIImage? {
        guard let review = yearlyReviewService.review else { return nil }

        let renderer = ImageRenderer(
            content: YearlyReviewShareCard(
                review: review,
                year: yearlyReviewService.currentYear
            )
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private var oneYearAgo: Date {
        Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
    }

    private var background: some View {
        LinearGradient(
            colors: [
                MemoryInkColors.parchment,
                MemoryInkColors.parchmentDeep,
                MemoryInkColors.paperWarm
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topTrailing) {
            RadialGradient(
                colors: [
                    Color.white.opacity(0.34),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 260
            )
            .frame(width: 260, height: 260)
            .offset(x: 72, y: -64)
        }
        .ignoresSafeArea()
    }

    private func moodGradient(_ mood: MoodType?) -> some View {
        LinearGradient(
            colors: [
                (mood?.tint ?? MemoryInkColors.sunlit).opacity(0.60),
                MemoryInkColors.paperWarm.opacity(0.84)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct YearlyReviewShareImage: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.data
        }
    }
}

private struct YearlyReviewShareCard: View {
    let review: YearlyReview
    let year: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("\(year)")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            Text("Your \(review.entryCount) Memories")
                .font(MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text(review.narrative)
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.ink)
                .lineSpacing(9)

            Spacer()

            Text("MemoryInk")
                .font(MemoryInkTypography.timestamp.weight(.medium))
                .foregroundStyle(MemoryInkColors.tertiaryInk)
        }
        .padding(54)
        .frame(width: 1080, height: 1080)
        .background(MemoryInkColors.parchment)
    }
}
