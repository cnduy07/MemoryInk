import PhotosUI
import SwiftUI

struct MemoryCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MemoryCreationViewModel

    init(
        repository: JournalEntryRepository,
        imagePipeline: ImagePipelineService,
        narrativeGenerationService: NarrativeGenerationService
    ) {
        _viewModel = StateObject(
            wrappedValue: MemoryCreationViewModel(
                repository: repository,
                imagePipeline: imagePipeline,
                narrativeGenerationService: narrativeGenerationService
            )
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let isCompact = proxy.size.height <= 670 || proxy.size.width <= 340
                let horizontalPadding: CGFloat = isCompact ? 16 : 20
                let contentWidth = min(proxy.size.width - (horizontalPadding * 2), 430)

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
            .onChange(of: viewModel.selectedPhotoItem) {
                Task {
                    await viewModel.loadSelectedPhoto()
                }
            }
            .onChange(of: viewModel.saveState) {
                if viewModel.saveState == .saved {
                    dismiss()
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
        PhotosPicker(
            selection: $viewModel.selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            GeometryReader { proxy in
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
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "photo")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundStyle(MemoryInkColors.tertiaryInk)

                            Text("Choose a photo")
                                .font(MemoryInkTypography.subtitle)
                                .foregroundStyle(MemoryInkColors.secondaryInk)
                        }
                    }
                }
            }
            .aspectRatio(4.0 / 5.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
            .shadow(color: MemoryInkColors.filmShadow.opacity(0.08), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
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
