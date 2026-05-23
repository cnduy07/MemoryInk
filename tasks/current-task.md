# Task W: Share image includes the memory photo

**Date:** 2026-05-23
**Phase:** Phase 3 — Monetization & Sync
**Priority:** High
**Estimated scope:** Small (2 files, surgical edits)

---

## Context

When a user taps the share button in `MemoryDetailView`, the app calls:

```swift
// MemoryDetailView.swift – shareCurrentMemory()
let image = MemoryShareRenderer.render(
    narrative: narrativeText(for: entry),
    mood: entry.mood,
    date: entry.createdAt
)
```

`MemoryShareRenderer.render(narrative:mood:date:)` only draws a gradient background + AI narrative text. The memory photo is **never passed in and never drawn**. The friend who receives the shared image sees only a gradient with text — no photo.

The fix is two-part:
1. Add an optional `photo: UIImage?` parameter to `MemoryShareRenderer.render(...)` and draw the photo full-bleed when one is present.
2. Pass `detailImage(for: entry)` from `shareCurrentMemory()` into the renderer.

---

## Files to modify

| File | Action |
|------|--------|
| `MemoryInk/Common/Components/MemoryShareRenderer.swift` | Add `photo` param; draw photo layout when present |
| `MemoryInk/Features/MemoryDetail/MemoryDetailView.swift` | Pass photo to renderer in `shareCurrentMemory()` |

**Do NOT touch:** any other file. TimelineView, MemoryCreationView, Typography, ShareSheet, AppRouter — untouched.

---

## Implementation spec

### Fix 1 — MemoryShareRenderer.swift

**Change the public signature from:**
```swift
static func render(narrative: String, mood: MoodType, date: Date) -> UIImage {
```
**To:**
```swift
static func render(narrative: String, mood: MoodType, date: Date, photo: UIImage? = nil) -> UIImage {
```

**Inside `renderer.image { context in ... }`, branch on `photo`:**

```swift
return renderer.image { context in
    let cgContext = context.cgContext
    let rect = CGRect(origin: .zero, size: size)

    if let photo = photo {
        drawPhoto(photo, in: rect)
        drawPhotoOverlay(in: rect, context: cgContext)
        drawBadgeWhite(mood: mood, in: rect)
        drawNarrativeWhite(narrative, in: rect)
        drawDateWhite(date, in: rect)
        drawWatermarkWhite(in: rect)
    } else {
        drawBackground(in: rect, mood: mood, context: cgContext)
        drawBadge(mood: mood, in: rect)
        drawNarrative(narrative, in: rect)
        drawDate(date, in: rect)
        drawWatermark(in: rect)
    }
}
```

**Add these four new private helpers (photo path only). Do NOT modify the existing five helpers — they must remain exactly as they are for the no-photo fallback.**

```swift
private static func drawPhoto(_ photo: UIImage, in rect: CGRect) {
    let photoSize = photo.size
    guard photoSize.width > 0, photoSize.height > 0 else { return }
    let scale = max(rect.width / photoSize.width, rect.height / photoSize.height)
    let scaledWidth = photoSize.width * scale
    let scaledHeight = photoSize.height * scale
    let drawRect = CGRect(
        x: (rect.width - scaledWidth) / 2,
        y: (rect.height - scaledHeight) / 2,
        width: scaledWidth,
        height: scaledHeight
    )
    photo.draw(in: drawRect)
}

private static func drawPhotoOverlay(in rect: CGRect, context: CGContext) {
    let colors = [
        UIColor.black.withAlphaComponent(0).cgColor,
        UIColor.black.withAlphaComponent(0.72).cgColor
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.25, 1.0]) else { return }
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.midX, y: rect.minY),
        end: CGPoint(x: rect.midX, y: rect.maxY),
        options: []
    )
}

private static func drawBadgeWhite(mood: MoodType, in rect: CGRect) {
    let badgeText = mood.title.uppercased()
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
        .foregroundColor: UIColor.white.withAlphaComponent(0.90)
    ]
    let textSize = badgeText.size(withAttributes: attributes)
    let badgeRect = CGRect(x: 92, y: 116, width: textSize.width + 42, height: 48)
    UIColor.white.withAlphaComponent(0.18).setFill()
    UIBezierPath(roundedRect: badgeRect, cornerRadius: 24).fill()
    badgeText.draw(at: CGPoint(x: badgeRect.minX + 21, y: badgeRect.minY + 11), withAttributes: attributes)
}

private static func drawNarrativeWhite(_ narrative: String, in rect: CGRect) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 8
    paragraph.alignment = .left
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 42, weight: .medium),
        .foregroundColor: UIColor.white,
        .paragraphStyle: paragraph
    ]
    let attributed = NSAttributedString(string: narrative, attributes: attributes)
    attributed.draw(
        with: CGRect(x: 92, y: 560, width: rect.width - 184, height: 380),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        context: nil
    )
}

private static func drawDateWhite(_ date: Date, in rect: CGRect) {
    let dateText = date.formatted(date: .abbreviated, time: .omitted)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 24, weight: .regular),
        .foregroundColor: UIColor.white.withAlphaComponent(0.72)
    ]
    dateText.draw(at: CGPoint(x: 92, y: 940), withAttributes: attributes)
}

private static func drawWatermarkWhite(in rect: CGRect) {
    let watermark = "MemoryInk"
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 22, weight: .medium),
        .foregroundColor: UIColor.white.withAlphaComponent(0.55)
    ]
    let size = watermark.size(withAttributes: attributes)
    watermark.draw(at: CGPoint(x: rect.maxX - size.width - 92, y: rect.maxY - 116), withAttributes: attributes)
}
```

**Rules for Fix 1:**
- The existing five helpers (`drawBackground`, `drawBadge`, `drawNarrative`, `drawDate`, `drawWatermark`) must be byte-for-byte identical to their current form.
- The four new helpers are only called when `photo != nil`.
- `photo` defaults to `nil` so all other call sites (if any) require no changes.
- No new imports needed — `UIKit` is already imported.

---

### Fix 2 — MemoryDetailView.swift

**In `shareCurrentMemory()` (currently lines 396–404), change from:**
```swift
private func shareCurrentMemory() {
    guard let entry = viewModel.entry else { return }

    let image = MemoryShareRenderer.render(
        narrative: narrativeText(for: entry),
        mood: entry.mood,
        date: entry.createdAt
    )
    shareItem = MemoryShareItem(image: image)
}
```

**To:**
```swift
private func shareCurrentMemory() {
    guard let entry = viewModel.entry else { return }

    let image = MemoryShareRenderer.render(
        narrative: narrativeText(for: entry),
        mood: entry.mood,
        date: entry.createdAt,
        photo: detailImage(for: entry)
    )
    shareItem = MemoryShareItem(image: image)
}
```

**Rules for Fix 2:**
- Only the `MemoryShareRenderer.render(...)` call changes — one new argument `photo: detailImage(for: entry)`.
- `detailImage(for:)` already exists at line 391–394; do not duplicate or move it.
- `detailImage(for:)` returns `nil` for slideshow memories (video path) — the renderer's `photo = nil` fallback handles that correctly, showing the gradient layout.
- No other code in `MemoryDetailView.swift` changes.

---

## Constraints

- [ ] Existing five `drawBackground/Badge/Narrative/Date/Watermark` helpers — zero changes
- [ ] No-photo path behavior is byte-for-byte identical to today
- [ ] No new Swift Packages
- [ ] No changes to `ShareSheet.swift`, `TimelineView.swift`, `MemoryCreationView.swift`, or any Model/Service file
- [ ] Slideshow memories (video-backed, `detailImage` returns nil) fall through to the existing gradient layout — no crash

---

## Success criteria

```bash
# Renderer now accepts photo param
grep -n "photo: UIImage?" MemoryInk/Common/Components/MemoryShareRenderer.swift
# must return: 1 match (the function signature)

# Four new helpers present
grep -n "func drawPhoto\|func drawPhotoOverlay\|func drawBadgeWhite\|func drawNarrativeWhite\|func drawDateWhite\|func drawWatermarkWhite" MemoryInk/Common/Components/MemoryShareRenderer.swift
# must return: 6 lines

# Original five helpers still present (unchanged)
grep -n "func drawBackground\|func drawBadge\b\|func drawNarrative\b\|func drawDate\b\|func drawWatermark\b" MemoryInk/Common/Components/MemoryShareRenderer.swift
# must return: 5 lines

# Call site passes photo
grep -n "photo: detailImage" MemoryInk/Features/MemoryDetail/MemoryDetailView.swift
# must return: 1 match

# Typecheck — zero errors
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun swiftc -typecheck -sdk "$SDK" -target arm64-apple-ios17.0-simulator \
  -parse-as-library -module-cache-path /private/tmp/MemoryInkMC \
  $(find MemoryInk -name "*.swift") 2>&1 | grep "error:"
# must produce no output

# Package.resolved still present
ls "MemoryInk.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
```

---

## Expected Codex response format

```
### Planned Changes
- MemoryShareRenderer.swift modify — add photo param + 6 new white-text helpers for photo layout
- MemoryDetailView.swift modify — pass detailImage(for:) as photo argument in shareCurrentMemory()

### Code
[Code here]

### Summary
- Files changed: [list]
- Behavior change: [1 sentence per fix]
- Not verified: [list]
- Needs human approval for next step: no
```
