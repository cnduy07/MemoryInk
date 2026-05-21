import SwiftUI
import UIKit

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

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingEditSheet = false
    @State private var shareItem: MemoryShareItem?

    init(viewModel: MemoryDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                if let entry = viewModel.entry {
                    imageArea(for: entry)
                    metadata(for: entry)
                    narrativeBlock(for: entry)
                } else {
                    Text("This memory is not available.")
                        .font(MemoryInkTypography.narrative)
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                        .padding(.top, 40)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MemoryInkSpacing.screenHorizontal)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(MemoryInkColors.parchment.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.image])
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
        Color.clear
            .aspectRatio(4.0 / 5.0, contentMode: .fit)
            .overlay {
                ZStack {
                    if let image = detailImage(for: entry) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
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
                    }

                    RadialGradient(
                        colors: [
                            entry.mood.tint.opacity(0.08),
                            MemoryInkColors.paper.opacity(0)
                        ],
                        center: .topTrailing,
                        startRadius: 12,
                        endRadius: 220
                    )
                }
            }
            .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
        }
        .shadow(color: MemoryInkColors.filmShadow.opacity(0.10), radius: 18, x: 0, y: 10)
    }

    private func metadata(for entry: JournalEntry) -> some View {
        HStack(alignment: .center, spacing: 12) {
            moodBadge(for: entry.mood)

            Rectangle()
                .fill(MemoryInkColors.hairline.opacity(0.36))
                .frame(width: 1, height: 16)

            if entry.aiNarrative?.isEmpty == false {
                Text(entry.narrativeStyle.rawValue.capitalized)
                    .font(MemoryInkTypography.badge)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(MemoryInkColors.paper.opacity(0.72))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(MemoryInkColors.hairline.opacity(0.22), lineWidth: 0.6)
                    }
            }

            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)

            Spacer()

            Button {
                viewModel.toggleFavorite()
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
            .buttonStyle(.plain)
            .accessibilityLabel(entry.isFavorite ? "Remove favorite" : "Mark favorite")
        }
    }

    private func narrativeBlock(for entry: JournalEntry) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(entry.mood.tint.opacity(0.45))
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
                    .buttonStyle(.plain)
                }
            }
            .padding(MemoryInkSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
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

        let image = MemoryShareRenderer.render(
            narrative: narrativeText(for: entry),
            mood: entry.mood,
            date: entry.createdAt
        )
        shareItem = MemoryShareItem(image: image)
    }
}

private struct MemoryShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
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
