import SwiftUI
import UIKit
import AVKit

@MainActor
struct MemoryDetailView: View {
    let entryId: UUID

    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var narrativeGenerationService: NarrativeGenerationService

    var body: some View {
        MemoryDetailContentView(
            viewModel: MemoryDetailViewModel(
                entryId: entryId,
                repository: repository,
                narrativeGenerationService: narrativeGenerationService
            )
        )
    }
}

@MainActor
private struct MemoryDetailContentView: View {
    let viewModel: MemoryDetailViewModel

    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingEditSheet = false
    @State private var shareItem: MemoryShareItem?

    init(viewModel: MemoryDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if let entry = viewModel.entry {
                    imageArea(for: entry)
                        .memoryInkEntrance()

                    VStack(alignment: .leading, spacing: 18) {
                        metadataRow(for: entry)
                            .memoryInkEntrance(delay: 0.04)
                        narrativeBlock(for: entry)
                            .memoryInkEntrance(delay: 0.08)
                        if let note = entry.rawNote, !note.isEmpty {
                            noteCard(note: note, mood: entry.mood)
                                .memoryInkEntrance(delay: 0.12)
                        }
                        similarMoments(for: entry)
                            .memoryInkEntrance(delay: 0.16)
                    }
                    .padding(.horizontal, MemoryInkSpacing.screenHorizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                } else {
                    Text("This memory is not available.")
                        .font(MemoryInkTypography.narrative)
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                        .padding(.top, 40)
                        .padding(.horizontal, MemoryInkSpacing.screenHorizontal)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            MemoryInkAmbientBackdrop(mood: viewModel.entry?.mood, intensity: 0.92)
                .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.entry != nil {
                    Menu {
                        Button {
                            isShowingEditSheet = true
                        } label: {
                            Label("Edit Memory", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            Label("Delete Memory", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    }
                    .accessibilityLabel("Memory actions")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.entry != nil {
                    Button {
                        shareCurrentMemory()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    }
                }
            }
        }
        .sheet(item: $shareItem) { item in
            MemoryShareCardSheet(
                narrative: item.narrative,
                mood: item.mood,
                date: item.date,
                photo: item.photo
            )
        }
        .confirmationDialog(
            "Delete this memory?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.delete()
            }

            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingEditSheet) {
            if let entry = viewModel.entry {
                EditMemorySheet(entry: entry) { mood, note in
                    viewModel.update(mood: mood, note: note)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("memoryDeleted"))) { _ in
            dismiss()
        }
    }

    @ViewBuilder
    private func imageArea(for entry: JournalEntry) -> some View {
        let screenWidth = UIScreen.main.bounds.width

        if let voicePath = entry.voicePath, voicePath.hasPrefix("slideshows/") {
            // Slideshow memory - show the MP4 video
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let videoURL = docsURL.appendingPathComponent(voicePath)
            SlideshowVideoPlayer(url: videoURL)
                .frame(width: screenWidth, height: 380)
                .clipped()
                .shadow(color: MemoryInkColors.filmShadow.opacity(0.12), radius: 18, x: 0, y: 10)
        } else {
            // Regular photo or mood gradient memory
            ZStack(alignment: .bottom) {
                if let image = detailImage(for: entry) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: screenWidth, height: 380)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [
                            entry.mood.tint.opacity(0.74),
                            MemoryInkColors.paperWarm,
                            MemoryInkColors.parchmentDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: screenWidth, height: 380)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.50)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: screenWidth, height: 380)

                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(entry.mood.tint)
                            .frame(width: 6, height: 6)

                        Text(entry.mood.title.uppercased())
                            .font(MemoryInkTypography.badge)
                            .kerning(0.6)
                            .foregroundStyle(MemoryInkColors.ink)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                    Spacer()

                    Text(entry.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
                .frame(width: screenWidth)
            }
            .frame(width: screenWidth, height: 380)
            .shadow(color: MemoryInkColors.filmShadow.opacity(0.12), radius: 18, x: 0, y: 10)
        }
    }


    private func metadataRow(for entry: JournalEntry) -> some View {
        HStack(alignment: .center, spacing: 12) {
            moodBadge(for: entry.mood)

            Text(entry.createdAt.formatted(date: .long, time: .omitted))
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(MemoryInkMotion.standard(reduceMotion: reduceMotion)) {
                    viewModel.toggleFavorite()
                }
            } label: {
                Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(entry.isFavorite ? entry.mood.tint : MemoryInkColors.secondaryInk)
                    .frame(width: 38, height: 38)
                    .background(MemoryInkColors.paper.opacity(0.92))
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.7)
                    }
                    .shadow(color: MemoryInkColors.filmShadow.opacity(0.08), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(MemoryInkPressStyle())
            .accessibilityLabel(entry.isFavorite ? "Remove favorite" : "Mark favorite")
        }
    }

    private func noteCard(note: String, mood: MoodType) -> some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: mood.gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 10) {
                Label("Your words", systemImage: "quote.opening")
                    .font(MemoryInkTypography.badge)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)

                Text(note)
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(MemoryInkColors.ink)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(MemoryInkSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [mood.tint.opacity(0.08), MemoryInkColors.paper, MemoryInkColors.paperWarm],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                .stroke(mood.tint.opacity(0.20), lineWidth: 0.8)
        }
    }

    private func narrativeBlock(for entry: JournalEntry) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: entry.mood.gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 14) {
                Text(narrativeText(for: entry))
                    .font(MemoryInkTypography.narrative)
                    .foregroundStyle(entry.aiNarrative?.isEmpty == false ? MemoryInkColors.ink : MemoryInkColors.secondaryInk)
                    .lineSpacing(9)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.narrativeState.canRetry {
                    Button {
                        viewModel.retry()
                    } label: {
                        Text("Try Again")
                            .font(MemoryInkTypography.timestamp.weight(.medium))
                            .foregroundStyle(MemoryInkColors.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(MemoryInkColors.paper.opacity(0.72))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.7)
                            }
                    }
                    .buttonStyle(MemoryInkPressStyle())
                }
            }
            .padding(MemoryInkSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [entry.mood.tint.opacity(0.08), MemoryInkColors.paper, MemoryInkColors.paperWarm],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                .stroke(entry.mood.tint.opacity(0.20), lineWidth: 0.8)
        }
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
            .overlay {
                Capsule()
                    .stroke(MemoryInkColors.paper.opacity(0.28), lineWidth: 0.6)
            }
    }

    @ViewBuilder
    private func similarMoments(for entry: JournalEntry) -> some View {
        let similar = Array(repository.entries.filter { $0.mood == entry.mood && $0.id != entry.id }.prefix(4))

        Group {
            if !similar.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("More \(entry.mood.title) moments")
                        .font(MemoryInkTypography.eyebrow)
                        .foregroundStyle(MemoryInkColors.tertiaryInk)
                        .textCase(.uppercase)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(similar) { similar in
                                similarTile(similar)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
        }
    }

    private func similarTile(_ entry: JournalEntry) -> some View {
        Button {
            router.path.append(.memoryDetail(id: entry.id))
        } label: {
            ZStack(alignment: .bottom) {
                if let img = ImagePipelineService.image(forRelativePath: entry.thumbnailPath) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 110)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: entry.mood.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                LinearGradient(colors: [.clear, .black.opacity(0.40)], startPoint: .center, endPoint: .bottom)

                Text(entry.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.90))
                    .padding(6)
            }
            .frame(width: 88, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(MemoryInkPressStyle())
    }

    private func narrativeText(for entry: JournalEntry) -> String {
        if let narrative = entry.aiNarrative, !narrative.isEmpty {
            return narrative
        }

        return viewModel.narrativeState.message ?? "Narrative will appear shortly."
    }

    private func detailImage(for entry: JournalEntry) -> UIImage? {
        ImagePipelineService.image(forRelativePath: entry.mediumPreviewPath)
            ?? ImagePipelineService.image(forRelativePath: entry.thumbnailPath)
    }

    private func shareCurrentMemory() {
        guard let entry = viewModel.entry else { return }

        // The card itself is rendered inside the share sheet, so the user can switch themes
        // and see the result before sending anything.
        shareItem = MemoryShareItem(
            narrative: narrativeText(for: entry),
            mood: entry.mood,
            date: entry.createdAt,
            photo: detailImage(for: entry)
        )
    }
}

private struct MemoryShareItem: Identifiable {
    let id = UUID()
    let narrative: String
    let mood: MoodType
    let date: Date
    let photo: UIImage?
}

private struct SlideshowVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = PlayerView()
        let player = AVPlayer(url: url)
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.itemDidEnd(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        context.coordinator.player = player
        player.play()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player = nil
        NotificationCenter.default.removeObserver(coordinator)
    }

    class Coordinator: NSObject {
        var player: AVPlayer?

        @objc func itemDidEnd(_ notification: Notification) {
            player?.seek(to: .zero)
            player?.play()
        }
    }

    private class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

@MainActor
private struct EditMemorySheet: View {
    let entry: JournalEntry
    let onSave: (MoodType, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: MoodType
    @State private var editedNote: String

    private let moodColumns = [
        GridItem(.adaptive(minimum: 96), spacing: 8)
    ]

    init(entry: JournalEntry, onSave: @escaping (MoodType, String) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _selectedMood = State(initialValue: entry.mood)
        _editedNote = State(initialValue: entry.rawNote ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(MemoryInkTypography.eyebrow)
                            .foregroundStyle(MemoryInkColors.tertiaryInk)
                            .textCase(.uppercase)

                        LazyVGrid(columns: moodColumns, alignment: .leading, spacing: 8) {
                            ForEach(MoodType.allCases) { mood in
                                Button {
                                    selectedMood = mood
                                } label: {
                                    Text(mood.title)
                                        .font(MemoryInkTypography.badge)
                                        .foregroundStyle(MemoryInkColors.ink.opacity(0.82))
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 9)
                                        .background(
                                            selectedMood == mood
                                                ? mood.tint.opacity(0.20)
                                                : MemoryInkColors.paper.opacity(0.72)
                                        )
                                        .clipShape(Capsule())
                                        .overlay {
                                            Capsule()
                                                .stroke(
                                                    selectedMood == mood
                                                        ? mood.tint.opacity(0.42)
                                                        : MemoryInkColors.hairline.opacity(0.22),
                                                    lineWidth: 0.7
                                                )
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(MemoryInkTypography.eyebrow)
                            .foregroundStyle(MemoryInkColors.tertiaryInk)
                            .textCase(.uppercase)

                        TextEditor(text: $editedNote)
                            .font(MemoryInkTypography.narrativeCompact)
                            .foregroundStyle(MemoryInkColors.ink)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 140)
                            .padding(12)
                            .background(MemoryInkColors.paper.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.7)
                            }
                    }
                }
                .padding(.horizontal, MemoryInkSpacing.screenHorizontal)
                .padding(.top, 22)
                .padding(.bottom, 34)
            }
            .background(MemoryInkColors.parchment.ignoresSafeArea())
            .navigationTitle("Edit Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedMood, editedNote)
                        dismiss()
                    }
                    .foregroundStyle(MemoryInkColors.ink)
                }
            }
        }
    }
}
