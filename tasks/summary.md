### Planned Changes
- MemoryCreationView.swift modify — Fix 1 (iPad width), Fix 2 (Spacer cap), Fix 3 (photoPreview Menu)
- tasks/summary.md modify — Record implementation summary and verification results

### Code
```swift
let contentWidth = finiteDimension(min(availableWidth, viewportSize.width > 700 ? 560 : 430))
```

```swift
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
```

```swift
Spacer(minLength: 0)
    .frame(maxHeight: 80)
```

### Summary
- Files changed: MemoryInk/Features/MemoryCreation/MemoryCreationView.swift; tasks/summary.md
- Behavior change: iPad creation content can expand to 560pt while iPhone remains capped at 430pt. The Memory Saved sheet spacer is capped so Done remains reachable on iPhone SE. The empty photo card now opens the same photo-type Menu when tapped.
- Checks run: `grep -n "viewportSize.width > 700" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift`; `grep -n "maxHeight: 80" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift`; `grep -n "Mood Backdrop" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift`; `grep -n "contentShape" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift`; `grep -n "@State private var" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift | wc -l`; `SDK=$(xcrun --sdk iphonesimulator --show-sdk-path) && xcrun swiftc -typecheck -sdk "$SDK" -target arm64-apple-ios17.0-simulator -parse-as-library -module-cache-path /private/tmp/MemoryInkMC $(find MemoryInk -name "*.swift") 2>&1 | grep "error:"`; `ls "MemoryInk.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"`
- Not verified: No simulator UI pass was run.
- Needs human approval for next step: no
