import PhotosUI
import SwiftUI

struct MemoryCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MemoryCreationViewModel
    @State private var showingScenePicker = false

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
                let contentWidth = finiteDimension(min(availableWidth, 430))

                ZStack {
                    background
                        .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: isCompact ? 18 : 22) {
                            photoPicker
                            MoodPickerView(selectedMood: $viewModel.selectedMood)
                            noteField(isCompact: isCompact)
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
                    Button(viewModel.saveState == .saving ? "Saving" : "Save") {
                        viewModel.save()
                    }
                    .disabled(!viewModel.canSave)
                    .foregroundStyle(viewModel.canSave ? MemoryInkColors.ink : MemoryInkColors.tertiaryInk)
                }
            }
            .onChange(of: viewModel.selectedPhotoItem) { _ in
                Task {
                    await viewModel.loadSelectedPhoto()
                }
            }
            .onChange(of: viewModel.saveState) { _ in
                if viewModel.saveState == .saved {
                    dismiss()
                }
            }
            .sheet(isPresented: $showingScenePicker) {
                ScenePickerSheet { scene in
                    viewModel.setBackgroundScene(scene)
                }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                MemoryInkColors.parchment,
                MemoryInkColors.paperWarm
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var photoPicker: some View {
        VStack(spacing: 12) {
            photoPreview

            if viewModel.selectedImage == nil {
                HStack(spacing: 12) {
                    PhotosPicker(
                        selection: $viewModel.selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("From Library", systemImage: "photo")
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

                    Button {
                        showingScenePicker = true
                    } label: {
                        Label("Choose Scene", systemImage: "paintbrush")
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
                HStack(spacing: 12) {
                    PhotosPicker(
                        selection: $viewModel.selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Change Photo")
                            .font(MemoryInkTypography.badge)
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                    }
                    .buttonStyle(.plain)

                    Button("Choose Scene") {
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
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(MemoryInkColors.tertiaryInk)

                        Text("Add a photo or choose a scene")
                            .font(MemoryInkTypography.subtitle)
                            .foregroundStyle(MemoryInkColors.secondaryInk)
                            .multilineTextAlignment(.center)
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
            .navigationTitle("Choose Background")
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
