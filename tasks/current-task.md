# Task C: Background Scenes for Memory Creation

**Date:** 2026-05-21
**Priority:** High

---

## Context

When creating a memory without a photo, users currently see a plain "Choose a photo" placeholder. This task adds 8 preset "scene" backgrounds — rendered purely in Swift as gradient UIImages via `UIGraphicsImageRenderer` (no new image files, no new packages, no CoreData changes). Users can tap "Choose scene" to pick a preset, or still use the existing photo library picker.

---

## Files

| File | Action |
|------|--------|
| `MemoryInk/Features/MemoryCreation/MemoryCreationView.swift` | **modify** |
| `MemoryInk/Features/MemoryCreation/MemoryCreationViewModel.swift` | **modify** — add `setBackgroundScene(_ scene: BackgroundScene)` method |
| `MemoryInk/Common/Components/BackgroundScene.swift` | **create** — scene definitions + renderer |

---

## Step 1 — `BackgroundScene.swift`

Create `MemoryInk/Common/Components/BackgroundScene.swift`:

```swift
import SwiftUI
import UIKit

struct BackgroundScene: Identifiable {
    let id: String
    let name: String
    let colors: [UIColor]
    let startPoint: CGPoint
    let endPoint: CGPoint

    static let all: [BackgroundScene] = [
        BackgroundScene(
            id: "golden_hour",
            name: "Golden Hour",
            colors: [UIColor(red: 0.98, green: 0.80, blue: 0.42, alpha: 1),
                     UIColor(red: 0.95, green: 0.55, blue: 0.30, alpha: 1),
                     UIColor(red: 0.72, green: 0.35, blue: 0.32, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "misty_morning",
            name: "Misty Morning",
            colors: [UIColor(red: 0.75, green: 0.85, blue: 0.95, alpha: 1),
                     UIColor(red: 0.60, green: 0.78, blue: 0.85, alpha: 1),
                     UIColor(red: 0.88, green: 0.92, blue: 0.90, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "sage_garden",
            name: "Sage Garden",
            colors: [UIColor(red: 0.55, green: 0.72, blue: 0.60, alpha: 1),
                     UIColor(red: 0.70, green: 0.82, blue: 0.68, alpha: 1),
                     UIColor(red: 0.88, green: 0.92, blue: 0.84, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "rose_dusk",
            name: "Rose Dusk",
            colors: [UIColor(red: 0.72, green: 0.42, blue: 0.50, alpha: 1),
                     UIColor(red: 0.88, green: 0.60, blue: 0.55, alpha: 1),
                     UIColor(red: 0.96, green: 0.82, blue: 0.72, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "night_ink",
            name: "Night Ink",
            colors: [UIColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 1),
                     UIColor(red: 0.14, green: 0.18, blue: 0.32, alpha: 1),
                     UIColor(red: 0.22, green: 0.28, blue: 0.42, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "ocean_calm",
            name: "Ocean Calm",
            colors: [UIColor(red: 0.22, green: 0.55, blue: 0.75, alpha: 1),
                     UIColor(red: 0.40, green: 0.72, blue: 0.85, alpha: 1),
                     UIColor(red: 0.75, green: 0.90, blue: 0.92, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "forest_deep",
            name: "Forest Deep",
            colors: [UIColor(red: 0.10, green: 0.28, blue: 0.18, alpha: 1),
                     UIColor(red: 0.22, green: 0.45, blue: 0.30, alpha: 1),
                     UIColor(red: 0.48, green: 0.65, blue: 0.45, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "warm_parchment",
            name: "Parchment",
            colors: [UIColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1),
                     UIColor(red: 0.88, green: 0.82, blue: 0.70, alpha: 1),
                     UIColor(red: 0.80, green: 0.74, blue: 0.62, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
    ]

    /// Renders this scene as a UIImage at the given size.
    func render(size: CGSize = CGSize(width: 800, height: 1000)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgContext = ctx.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgColors = colors.map(\.cgColor) as CFArray
            let locations: [CGFloat] = colors.enumerated().map { i, _ in
                CGFloat(i) / CGFloat(max(colors.count - 1, 1))
            }
            guard let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: cgColors,
                locations: locations
            ) else { return }

            let start = CGPoint(x: startPoint.x * size.width, y: startPoint.y * size.height)
            let end = CGPoint(x: endPoint.x * size.width, y: endPoint.y * size.height)
            cgContext.drawLinearGradient(
                gradient,
                start: start,
                end: end,
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
    }

    /// Returns a SwiftUI Color for previewing (uses the middle color).
    var previewColors: [Color] {
        colors.map { Color(uiColor: $0) }
    }
}
```

---

## Step 2 — `MemoryCreationViewModel.swift`

Add one method after `loadSelectedPhoto()`:

```swift
func setBackgroundScene(_ scene: BackgroundScene) {
    selectedImage = scene.render()
}
```

Do NOT change any other existing method.

---

## Step 3 — `MemoryCreationView.swift`

Add `@State private var showingScenePicker = false` to the view.

### 3a — Restructure `photoPicker`

Replace the existing `photoPicker` computed property with a new one that separates the preview area from the action buttons:

```swift
private var photoPicker: some View {
    VStack(spacing: 12) {
        // Preview area (no longer the picker trigger itself)
        photoPreview

        // Action buttons — only shown if no image selected
        if viewModel.selectedImage == nil {
            HStack(spacing: 12) {
                // Library picker
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

                // Scene picker
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
            // Change button shown when an image is already selected
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
    .sheet(isPresented: $showingScenePicker) {
        ScenePickerSheet { scene in
            viewModel.setBackgroundScene(scene)
        }
    }
}
```

### 3b — `photoPreview` computed property

```swift
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
```

### 3c — `ScenePickerSheet` (private struct in the same file)

Add at the bottom of `MemoryCreationView.swift`:

```swift
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
```

---

## Important: Add file to Xcode project

Add `MemoryInk/Common/Components/BackgroundScene.swift` to the Xcode project target in `MemoryInk.xcodeproj/project.pbxproj`.

---

## Constraints

- [ ] No new Swift Package, no CoreData changes
- [ ] `canSave` logic unchanged (`selectedImage != nil && saveState != .saving`) — scenes set `selectedImage` so Save button enables correctly
- [ ] `loadSelectedPhoto()` and `save()` in ViewModel unchanged
- [ ] The `finiteSize`/`finiteDimension` helpers in MemoryCreationView unchanged

## Success Criteria

- [ ] "From Library" and "Choose Scene" buttons shown when no image selected
- [ ] Tapping "Choose Scene" shows a 3-column grid sheet of 8 gradient tiles
- [ ] Selecting a scene dismisses sheet and shows the gradient in the preview
- [ ] Save button enables after selecting a scene
- [ ] Memory saves normally (scene image stored via existing imagePipeline)
- [ ] Xcode compiles without errors

Save report to `tasks/summary.md`.
