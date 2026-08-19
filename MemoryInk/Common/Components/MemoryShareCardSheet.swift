import SwiftUI
import UIKit

/// The one place a memory becomes a shareable card: a live preview, a few themes to choose
/// from, and then the system share sheet.
///
/// Every share entry point in the app (Timeline, Detail, Browse, after creating a memory) goes
/// through this, so the choice and the preview are the same everywhere. Nothing here uploads
/// anything — the image is handed straight to `UIActivityViewController` for the user to send.
struct MemoryShareCardSheet: View {
    let narrative: String
    let mood: MoodType
    let date: Date
    var photo: UIImage?
    /// Optional text shared alongside the image (used after creating a memory).
    var caption: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("share_card_theme") private var selectedThemeId: String = MemoryShareTheme.classic.id
    @State private var isShowingShareSheet = false
    /// Rendered once per theme rather than on every layout pass — the card is 2160×2160.
    @State private var card: UIImage?

    private var theme: MemoryShareTheme {
        MemoryShareTheme.theme(id: selectedThemeId)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                cardPreview
                    .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.radiusLarge, style: .continuous))
                    .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 12)
                    .padding(.horizontal, 26)
                    .animation(MemoryInkMotion.standard(reduceMotion: reduceMotion), value: selectedThemeId)

                themePicker

                shareButton
                    .padding(.horizontal, 26)
                    .padding(.bottom, 8)
            }
            .padding(.top, 18)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(MemoryInkAmbientBackdrop(mood: mood, intensity: 0.9).ignoresSafeArea())
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                }
            }
            .task(id: selectedThemeId) {
                card = MemoryShareRenderer.render(
                    narrative: narrative,
                    mood: mood,
                    date: date,
                    photo: photo,
                    theme: theme
                )
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    @ViewBuilder
    private var cardPreview: some View {
        if let card {
            Image(uiImage: card)
                .resizable()
                .scaledToFit()
        } else {
            // Same 1:1 footprint as the card, so nothing jumps when it arrives.
            Rectangle()
                .fill(MemoryInkColors.paper.opacity(0.55))
                .aspectRatio(1, contentMode: .fit)
        }
    }

    private var themePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(MemoryShareTheme.all.enumerated()), id: \.element.id) { index, option in
                    Button {
                        MemoryInkHaptics.selection()
                        selectedThemeId = option.id
                    } label: {
                        themeChip(option)
                    }
                    .buttonStyle(MemoryInkPressStyle())
                    .padding(.leading, index == 0 ? 26 : 0)
                    .padding(.trailing, index == MemoryShareTheme.all.count - 1 ? 26 : 0)
                }
            }
        }
    }

    private func themeChip(_ option: MemoryShareTheme) -> some View {
        let isSelected = option.id == selectedThemeId

        return VStack(spacing: 7) {
            Group {
                if let scene = option.scene {
                    LinearGradient(
                        colors: scene.previewColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        colors: [mood.tint.opacity(0.55), MemoryInkColors.parchment],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.radiusSmall, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MemoryInkSpacing.radiusSmall, style: .continuous)
                    .stroke(
                        isSelected ? MemoryInkColors.ink.opacity(0.55) : MemoryInkColors.hairline.opacity(0.30),
                        lineWidth: isSelected ? 1.6 : 0.8
                    )
            }

            Text(option.name)
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(isSelected ? MemoryInkColors.ink : MemoryInkColors.tertiaryInk)
        }
    }

    private var shareButton: some View {
        Button {
            MemoryInkHaptics.light()
            isShowingShareSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                Text("Share this memory")
                    .font(MemoryInkTypography.subtitle.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: mood.gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.radiusMedium, style: .continuous))
            .shadow(color: mood.tint.opacity(0.26), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(MemoryInkPressStyle())
        .disabled(card == nil)
        .opacity(card == nil ? 0.55 : 1)
    }

    private var shareItems: [Any] {
        var items: [Any] = []
        if let card {
            items.append(card)
        }
        if let caption, !caption.isEmpty {
            items.append(caption)
        }
        return items
    }
}
