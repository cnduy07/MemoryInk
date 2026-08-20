import PhotosUI
import SwiftUI

struct MemoryCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MemoryCreationViewModel
    @State private var showingScenePicker = false
    @State private var showingLibraryPicker = false
    @State private var showingCollagePicker = false
    @State private var showingCreationSlideshow = false
    @State private var showingSuccessSheet = false

    init(
        repository: JournalEntryRepository,
        imagePipeline: ImagePipelineService,
        narrativeGenerationService: NarrativeGenerationService,
        analyticsService: AnalyticsService? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: MemoryCreationViewModel(
                repository: repository,
                imagePipeline: imagePipeline,
                narrativeGenerationService: narrativeGenerationService,
                analyticsService: analyticsService
            )
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let viewportSize = finiteSize(proxy.size)
                let isCompact = viewportSize.height <= 670 || viewportSize.width <= 340
                let horizontalPadding: CGFloat = isCompact ? 16 : 20
                let availableWidth = finiteDimension(viewportSize.width - (horizontalPadding * 2))
                let contentWidth = finiteDimension(min(availableWidth, viewportSize.width > 700 ? 560 : 430))

                ZStack {
                    MemoryInkAmbientBackdrop(mood: viewModel.selectedMood, intensity: 1.05)
                        .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: isCompact ? 18 : 22) {
                            photoPicker
                                .memoryInkEntrance()
                            MoodPickerView(selectedMood: $viewModel.selectedMood)
                                .memoryInkEntrance(delay: 0.04)
                            noteField(isCompact: isCompact)
                                .memoryInkEntrance(delay: 0.08)
                        }
                        .frame(width: contentWidth, alignment: .leading)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, isCompact ? 14 : 22)
                        .padding(.bottom, isCompact ? 28 : 40)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("New memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.save()
                    } label: {
                        Group {
                            if viewModel.saveState == .saving {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                    Text("Saving")
                                }
                            } else {
                                Text("Save")
                            }
                        }
                        .font(MemoryInkTypography.badge.weight(.semibold))
                        .foregroundStyle(MemoryInkColors.onAccent)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: viewModel.canSave
                                    ? viewModel.selectedMood.gradientColors
                                    : [
                                        MemoryInkColors.tertiaryInk.opacity(0.35),
                                        MemoryInkColors.tertiaryInk.opacity(0.24)
                                    ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(
                            color: viewModel.canSave ? viewModel.selectedMood.tint.opacity(0.24) : .clear,
                            radius: 9,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(!viewModel.canSave)
                    .buttonStyle(MemoryInkPressStyle())
                }
            }
            .onChange(of: viewModel.selectedPhotoItem) { _ in
                Task { await viewModel.loadSelectedPhoto() }
            }
            .onChange(of: viewModel.selectedCollageItems) { _ in
                Task { await viewModel.loadCollagePhotos() }
            }
            .onChange(of: viewModel.saveState) { _ in
                if viewModel.saveState == .saved {
                    // Close any open sub-sheet first, then wait for dismissal animation
                    // before presenting success sheet. Without the delay, SwiftUI drops
                    // the success sheet when a slideshow creation sheet is mid-dismissal.
                    showingCreationSlideshow = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        showingSuccessSheet = true
                    }
                }
            }
            .photosPicker(
                isPresented: $showingLibraryPicker,
                selection: $viewModel.selectedPhotoItem,
                matching: .images
            )
            .photosPicker(
                isPresented: $showingCollagePicker,
                selection: $viewModel.selectedCollageItems,
                maxSelectionCount: 4,
                matching: .images
            )
            .sheet(isPresented: $showingScenePicker) {
                ScenePickerSheet { scene in
                    viewModel.setBackgroundScene(scene)
                }
            }
            .sheet(isPresented: $showingCreationSlideshow) {
                CreationSlideshowSheet(mood: viewModel.selectedMood) { firstImage, videoURL, chosenMood in
                    viewModel.saveAsSlideshow(firstImage: firstImage, videoURL: videoURL, mood: chosenMood)
                }
            }
            .sheet(isPresented: $showingSuccessSheet) {
                if let entry = viewModel.savedEntry {
                    MemorySavedSheet(entry: entry, repository: viewModel.repository) {
                        showingSuccessSheet = false
                        dismiss()
                    }
                }
            }
        }
    }

    private var photoPicker: some View {
        VStack(spacing: 12) {
            photoPreview

            if viewModel.selectedImage == nil {
                HStack(spacing: 12) {
    Menu {
        Button("From Library") { showingLibraryPicker = true }
        Button("Photo Collage (up to 4)") { showingCollagePicker = true }
        Button("Short Slideshow (up to 5 photos)") { showingCreationSlideshow = true }
    } label: {
                        Label("Add Photo", systemImage: "photo.badge.plus")
                            .font(MemoryInkTypography.badge)
                            .foregroundStyle(MemoryInkColors.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(MemoryInkColors.paper.opacity(0.88))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.7)
                            }
                    }

                    Button {
                        showingScenePicker = true
                    } label: {
                        Label("Mood Backdrop", systemImage: "paintpalette")
                            .font(MemoryInkTypography.badge)
                            .foregroundStyle(MemoryInkColors.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(MemoryInkColors.paper.opacity(0.88))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.7)
                            }
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 20) {
    Menu {
        Button("From Library") { showingLibraryPicker = true }
        Button("Photo Collage (up to 4)") { showingCollagePicker = true }
        Button("Short Slideshow (up to 5 photos)") { showingCreationSlideshow = true }
        Button("Mood Backdrop") { showingScenePicker = true }
    } label: {
                        Label("Change", systemImage: "arrow.triangle.2.circlepath")
                            .font(MemoryInkTypography.badge)
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    }

                    Button("Mood Backdrop") {
                        showingScenePicker = true
                    }
                    .font(MemoryInkTypography.badge)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var photoPreview: some View {
        GeometryReader { proxy in
            let imageSize = finiteSize(proxy.size)

            ZStack {
                RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                    .fill(MemoryInkColors.paper.opacity(0.88))
                    .overlay {
                        RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                            .stroke(MemoryInkColors.hairline.opacity(0.30), lineWidth: 0.8)
                    }

                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize.width, height: imageSize.height)
                        .clipped()
                    if viewModel.isBackdropSelected {
                        VStack(spacing: 12) {
                            Text(viewModel.selectedMood.emoji)
                                .font(.system(size: 64))
                            Text(viewModel.selectedMood.title)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                } else {
                    Menu {
                        Button("From Library") { showingLibraryPicker = true }
                        Button("Photo Collage (up to 4)") { showingCollagePicker = true }
                        Button("Short Slideshow (up to 5 photos)") { showingCreationSlideshow = true }
                        Button("Mood Backdrop") { showingScenePicker = true }
                    } label: {
                        VStack(spacing: 14) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(MemoryInkColors.amber.opacity(0.70))

                            Text("Tap to add a photo")
                                .font(MemoryInkTypography.subtitle)
                                .foregroundStyle(MemoryInkColors.secondaryInk)

                            Text("Single · Collage · Slideshow · Mood")
                                .font(MemoryInkTypography.timestamp)
                                .foregroundStyle(MemoryInkColors.tertiaryInk)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        .aspectRatio(4.0 / 5.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .shadow(color: MemoryInkColors.filmShadow.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private func finiteSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: finiteDimension(size.width),
            height: finiteDimension(size.height)
        )
    }

    private func finiteDimension(_ value: CGFloat, fallback: CGFloat = 0) -> CGFloat {
        guard value.isFinite else {
            return fallback
        }

        return max(value, 0)
    }

    private func noteField(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Note")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            TextEditor(text: $viewModel.note)
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: isCompact ? 96 : 118)
                .padding(12)
                .background(MemoryInkColors.paper.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MemoryInkColors.hairline.opacity(0.26), lineWidth: 0.8)
                }
        }
    }
}

private struct ScenePickerSheet: View {
    let onSelect: (BackgroundScene) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(BackgroundScene.all) { scene in
                        Button {
                            onSelect(scene)
                            dismiss()
                        } label: {
                            ZStack(alignment: .bottom) {
                                LinearGradient(
                                    colors: scene.previewColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )

                                Text(scene.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .padding(.bottom, 8)
                            }
                            .frame(height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(MemoryInkColors.parchment.ignoresSafeArea())
            .navigationTitle("Mood Backdrop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                }
            }
        }
    }
}

private struct MemorySavedSheet: View {
    let entry: JournalEntry
    @ObservedObject var repository: JournalEntryRepository
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var checkmarkScale: CGFloat = 0.4
    @State private var showShareSheet = false

    /// The saved entry as it stands *now*. `entry` is a snapshot from the moment of saving,
    /// taken before the AI narrative exists — reading through the repository means the share
    /// card picks up the narrative as soon as it arrives.
    private var liveEntry: JournalEntry {
        repository.entries.first { $0.id == entry.id } ?? entry
    }

    /// The user's own words are the best thing to share; the narrative is better still once
    /// it lands. Never leave the card with nothing on it.
    private var shareNarrative: String {
        if let narrative = liveEntry.aiNarrative, !narrative.isEmpty { return narrative }
        if let note = liveEntry.rawNote, !note.isEmpty { return note }
        return "A \(liveEntry.mood.title.lowercased()) moment, kept."
    }

    private var sharePhoto: UIImage? {
        ImagePipelineService.image(forRelativePath: liveEntry.mediumPreviewPath)
            ?? ImagePipelineService.image(forRelativePath: liveEntry.thumbnailPath)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 38, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 32)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: entry.mood.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(checkmarkScale)
                .animation(MemoryInkMotion.standard(reduceMotion: reduceMotion), value: checkmarkScale)
                .padding(.bottom, 20)

            Text("Memory saved")
                .font(.system(size: 32, weight: .semibold, design: .default))
                .foregroundStyle(MemoryInkColors.ink)

            Text(entry.createdAt.formatted(date: .long, time: .omitted))
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .padding(.top, 6)

            Text(entry.mood.title)
                .font(MemoryInkTypography.badge)
                .foregroundStyle(MemoryInkColors.onAccent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: entry.mood.gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .padding(.top, 18)

            Spacer(minLength: 0)
                .frame(maxHeight: 80)

            Text("Your AI narrative is being crafted…")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .padding(.bottom, 12)

            Button {
                MemoryInkHaptics.light()
                showShareSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Share this moment")
                        .font(MemoryInkTypography.subtitle.weight(.semibold))
                }
                .foregroundStyle(MemoryInkColors.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: entry.mood.gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: entry.mood.tint.opacity(0.28), radius: 14, x: 0, y: 6)
            }
            .buttonStyle(MemoryInkPressStyle())
            .padding(.horizontal, 28)

            Button("Done") {
                onDone()
            }
            .font(MemoryInkTypography.subtitle.weight(.medium))
            .foregroundStyle(MemoryInkColors.secondaryInk)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity)
        .background(
            MemoryInkAmbientBackdrop(mood: entry.mood, intensity: 1.05)
            .ignoresSafeArea()
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showShareSheet) {
            MemoryShareCardSheet(
                narrative: shareNarrative,
                mood: liveEntry.mood,
                date: liveEntry.createdAt,
                photo: sharePhoto,
                caption: "I captured this moment with MemoryInk ✨"
            )
        }
        .onAppear {
            checkmarkScale = 1.0
        }
    }
}

private struct CreationSlideshowSheet: View {
    let mood: MoodType
    let onCreated: (UIImage, URL, MoodType) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var slideshowService = SlideshowService()

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var isLoadingImages = false
    @State private var errorMessage: String?
    @State private var selectedStyle: SlideshowStyle = .natural
    @State private var localMood: MoodType

    private var maxPhotos: Int { 5 }
    private let previewColumns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    init(mood: MoodType, onCreated: @escaping (UIImage, URL, MoodType) -> Void) {
        self.mood = mood
        self.onCreated = onCreated
        _localMood = State(initialValue: mood)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select 2–\(maxPhotos) photos")
                            .font(MemoryInkTypography.subtitle.weight(.medium))
                            .foregroundStyle(MemoryInkColors.ink)
                        Text("A 10-second slideshow will be created and saved")
                            .font(MemoryInkTypography.timestamp)
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    }
                    Spacer()
                    Text("10 sec")
                        .font(MemoryInkTypography.badge)
                        .foregroundStyle(MemoryInkColors.amber)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(MemoryInkColors.amber.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(MemoryInkColors.paperWarm)

                Divider()

                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: maxPhotos,
                    matching: .images
                ) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 16, weight: .medium))
                        Text(selectedItems.isEmpty
                             ? "Choose Photos"
                             : "Change Selection (\(selectedItems.count))")
                            .font(MemoryInkTypography.badge.weight(.medium))
                    }
                    .foregroundStyle(MemoryInkColors.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(MemoryInkColors.paper.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.7)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .onChange(of: selectedItems) { _ in
                    Task { await loadImages() }
                }

                if !loadedImages.isEmpty {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: previewColumns, spacing: 3) {
                            ForEach(Array(loadedImages.enumerated()), id: \.offset) { idx, image in
                                ZStack(alignment: .topLeading) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(
                                            width: (UIScreen.main.bounds.width - 6) / 3,
                                            height: (UIScreen.main.bounds.width - 6) / 3
                                        )
                                        .clipped()
                                    Text("\(idx + 1)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.black.opacity(0.55))
                                        .clipShape(Circle())
                                        .padding(5)
                                }
                                .contentShape(Rectangle())
                            }
                        }
                    }
                } else if isLoadingImages {
                    ProgressView("Loading photos…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                }

                if !loadedImages.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(MemoryInkTypography.timestamp.weight(.medium))
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MoodType.allCases) { moodOption in
                                    let isSelected = localMood == moodOption
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            localMood = moodOption
                                        }
                                    } label: {
                                        Text("\(moodOption.emoji) \(moodOption.title)")
                                            .font(MemoryInkTypography.timestamp.weight(isSelected ? .semibold : .regular))
                                            .foregroundStyle(isSelected ? .white : moodOption.tint)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? moodOption.tint : moodOption.tint.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 10)
                }

                if !loadedImages.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style")
                            .font(MemoryInkTypography.timestamp.weight(.medium))
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(SlideshowStyle.allCases) { style in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedStyle = style
                                        }
                                    } label: {
                                        VStack(spacing: 5) {
                                            Image(systemName: style.icon)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundStyle(selectedStyle == style ? .white : style.accentColor)
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    selectedStyle == style
                                                        ? style.accentColor
                                                        : style.accentColor.opacity(0.12)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                .overlay {
                                                    if selectedStyle == style {
                                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                            .stroke(style.accentColor, lineWidth: 2)
                                                    }
                                                }

                                            Text(style.title)
                                                .font(.system(size: 10, weight: selectedStyle == style ? .semibold : .regular))
                                                .foregroundStyle(selectedStyle == style ? style.accentColor : MemoryInkColors.tertiaryInk)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 10)
                }

                Spacer(minLength: 0)

                Divider()

                VStack(spacing: 8) {
                    if slideshowService.isGenerating {
                        ProgressView(value: slideshowService.progress)
                            .progressViewStyle(.linear)
                            .tint(MemoryInkColors.amber)
                            .padding(.horizontal, 22)
                        Text("Creating slideshow… \(Int(slideshowService.progress * 100))%")
                            .font(MemoryInkTypography.timestamp)
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    } else {
                        Button {
                            guard loadedImages.count >= 2 else { return }
                            Task {
                                do {
                                    let url = try await slideshowService.generateFromImages(
                                        loadedImages,
                                        mood: localMood,
                                        style: selectedStyle,
                                        isPremium: subscriptionManager.hasPremiumEntitlement,
                                        totalSeconds: 10
                                    )
                                    let firstFrame = loadedImages[0]
                                    onCreated(firstFrame, url, localMood)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            Text(loadedImages.count < 2
                                 ? "Select at least 2 photos"
                                 : "Create 10-Second Slideshow")
                                .font(MemoryInkTypography.subtitle.weight(.semibold))
                                .foregroundStyle(MemoryInkColors.onAccent)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    loadedImages.count >= 2
                                        ? LinearGradient(
                                            colors: [MemoryInkColors.amber, MemoryInkColors.sunlit],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        : LinearGradient(
                                            colors: [
                                                MemoryInkColors.tertiaryInk.opacity(0.35),
                                                MemoryInkColors.tertiaryInk.opacity(0.35)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(loadedImages.count < 2)
                        .padding(.horizontal, 22)
                    }
                }
                .padding(.vertical, 16)
                .background(MemoryInkColors.paperWarm.opacity(0.95))
            }
            .background(MemoryInkColors.parchment.ignoresSafeArea())
            .navigationTitle("Short Slideshow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(MemoryInkTypography.timestamp.weight(.medium))
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func loadImages() async {
        isLoadingImages = true
        var images: [UIImage] = []
        for item in selectedItems {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                continue
            }
            images.append(image)
        }
        loadedImages = images
        isLoadingImages = false
    }
}
