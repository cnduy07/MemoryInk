import SwiftUI

struct SlideshowPickerView: View {
    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var slideshowService = SlideshowService()
    @State private var selectedIds: [UUID] = []
    @State private var selectedMood: MoodType = .happy
    @State private var selectedStyle: SlideshowStyle = .natural
    @State private var exportedURL: URL?
    @State private var showShareSheet: Bool = false
    @State private var showUpgradePrompt: Bool = false
    @State private var errorMessage: String?

    private var maxSelectable: Int { subscriptionManager.hasPremiumEntitlement ? 10 : 3 }
    private var entries: [JournalEntry] { repository.entries }
    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                selectionHeader
                    .memoryInkEntrance()
                hairlineDivider
                moodPicker
                    .memoryInkEntrance(delay: 0.04)
                stylePicker
                    .memoryInkEntrance(delay: 0.08)
                hairlineDivider
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(entries) { entry in
                            gridCell(entry: entry)
                        }
                    }
                }
                .memoryInkEntrance(delay: 0.12)
                hairlineDivider
                bottomBar
                    .memoryInkEntrance(delay: 0.16)
            }
            .background(MemoryInkAmbientBackdrop(mood: selectedMood, intensity: 0.9).ignoresSafeArea())
            .navigationTitle("Create Slideshow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(MemoryInkTypography.timestamp.weight(.medium))
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                        .onDisappear {
                            try? FileManager.default.removeItem(at: url)
                            exportedURL = nil
                        }
                }
            }
            .alert("Upgrade to MemoryInk+", isPresented: $showUpgradePrompt) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Free accounts can include up to 3 memories. Upgrade to MemoryInk+ for slideshows with up to 10.")
            }
            .alert("Export failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Subviews

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MemoryInkColors.hairline.opacity(0.3))
            .frame(height: 0.8)
    }

    private var selectionHeader: some View {
        HStack {
            Text(selectedIds.isEmpty
                ? "Tap memories to select"
                : "\(selectedIds.count) of \(maxSelectable) selected")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.secondaryInk)
            Spacer()
            if !subscriptionManager.hasPremiumEntitlement {
                Text("Free: up to 3")
                    .font(MemoryInkTypography.badge)
                    .foregroundStyle(MemoryInkColors.amber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(MemoryInkColors.amber.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(MemoryInkColors.paperWarm)
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MOOD")
                .font(MemoryInkTypography.badge)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MoodType.allCases) { mood in
                        let isSelected = selectedMood == mood
                        Button {
                            MemoryInkHaptics.selection()
                            selectedMood = mood
                        } label: {
                            Text("\(mood.emoji) \(mood.title)")
                                .font(MemoryInkTypography.timestamp.weight(isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? .white : mood.tint)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? mood.tint : mood.tint.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(MemoryInkPressStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(MemoryInkColors.paperWarm)
    }

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STYLE")
                .font(MemoryInkTypography.badge)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SlideshowStyle.allCases) { style in
                        let isSelected = selectedStyle == style
                        Button {
                            MemoryInkHaptics.selection()
                            selectedStyle = style
                        } label: {
                            Text(style.title)
                                .font(MemoryInkTypography.timestamp.weight(isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? .white : MemoryInkColors.ink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? MemoryInkColors.amber : MemoryInkColors.amber.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(MemoryInkPressStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
        }
        .padding(.bottom, 10)
        .background(MemoryInkColors.paperWarm)
    }

    private func gridCell(entry: JournalEntry) -> some View {
        let tileSize = (UIScreen.main.bounds.width - 6) / 3
        let selectionIndex = selectedIds.firstIndex(of: entry.id)
        let isSelected = selectionIndex != nil

        return ZStack(alignment: .topTrailing) {
            Group {
                if let img = ImagePipelineService.image(forRelativePath: entry.thumbnailPath) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [entry.mood.tint.opacity(0.8), entry.mood.tint.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: tileSize, height: tileSize)
            .clipped()

            if isSelected {
                Color.black.opacity(0.35)
                    .frame(width: tileSize, height: tileSize)
                Text("\((selectionIndex ?? 0) + 1)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(MemoryInkColors.amber)
                    .clipShape(Circle())
                    .padding(6)
            }
        }
        .frame(width: tileSize, height: tileSize)
        .contentShape(Rectangle())
        .onTapGesture {
            MemoryInkHaptics.selection()
            if let idx = selectedIds.firstIndex(of: entry.id) {
                selectedIds.remove(at: idx)
            } else if selectedIds.count < maxSelectable {
                selectedIds.append(entry.id)
            } else {
                showUpgradePrompt = true
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if slideshowService.isGenerating {
                ProgressView(value: slideshowService.progress)
                    .progressViewStyle(.linear)
                    .tint(MemoryInkColors.amber)
                    .padding(.horizontal, 22)
                Text("Creating your slideshow... \(Int(slideshowService.progress * 100))%")
                    .font(MemoryInkTypography.timestamp)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
            } else {
                Button {
                    MemoryInkHaptics.medium()
                    guard selectedIds.count >= 2 else { return }
                    let orderedEntries = selectedIds.compactMap { id in
                        entries.first { $0.id == id }
                    }
                    let images = orderedEntries.compactMap {
                        ImagePipelineService.image(forRelativePath: $0.thumbnailPath)
                    }
                    guard images.count >= 2 else {
                        errorMessage = "At least 2 selected memories must have photos."
                        return
                    }
                    Task {
                        do {
                            let url = try await slideshowService.generateFromImages(
                                images,
                                mood: selectedMood,
                                style: selectedStyle,
                                isPremium: subscriptionManager.hasPremiumEntitlement
                            )
                            exportedURL = url
                            showShareSheet = true
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    Text(selectedIds.count < 2
                        ? "Select at least 2 memories"
                        : "Create Slideshow (\(selectedIds.count))")
                        .font(MemoryInkTypography.subtitle.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            selectedIds.count >= 2
                                ? LinearGradient(
                                    colors: [MemoryInkColors.amber, MemoryInkColors.sunlit],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [MemoryInkColors.tertiaryInk.opacity(0.4), MemoryInkColors.tertiaryInk.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(MemoryInkPressStyle())
                .disabled(selectedIds.count < 2)
                .padding(.horizontal, 22)
            }
        }
        .padding(.vertical, 16)
        .background(MemoryInkColors.paperWarm.opacity(0.95))
    }
}
