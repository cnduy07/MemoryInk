# Task S: Fix upside-down video and short slideshow photo limit

**Date:** 2026-05-23
**Phase:** Phase 3 — Monetization & Sync
**Priority:** Critical
**Estimated scope:** Small (4 lines removed in SlideshowService, 2 lines changed in MemoryCreationView)

---

## Fix 1 — Remove Y-flip from CVPixelBuffer copy step (SlideshowService.swift)

### Root cause

The CVPixelBuffer `CGContext` on iOS has its y=0 at the **first row of the buffer**, which is the TOP of the video frame. This makes it effectively a y-down coordinate system. `CGContext.draw(cgImage, in:)` in this context places the cgImage's row 0 (the top of the rendered UIGraphicsImageRenderer output) at y=0 (the first buffer row = TOP of video) — correct.

Task P added a Y-flip (`translateBy` + `scaleBy`) before the draw call. This flip inverts the mapping:
- User y=0 → device y=height → LAST buffer row → BOTTOM of video
- cgImage row 0 (top) now lands at the BOTTOM of the video → video is upside down.

**Fix:** Remove the two Y-flip lines in BOTH `renderFrame` and `renderImageFrame`.

### In `renderFrame` (around line 332), remove exactly these two lines:
```swift
        context.translateBy(x: 0, y: CGFloat(Constants.height))
        context.scaleBy(x: 1, y: -1)
```
Leave `context.draw(cgImage, in: canvasRect)` and `return pixelBuffer` untouched.

### In `renderImageFrame` (around line 461), remove exactly the same two lines:
```swift
        context.translateBy(x: 0, y: CGFloat(Constants.height))
        context.scaleBy(x: 1, y: -1)
```
Leave `context.draw(cgImage, in: canvasRect)` and `return pixelBuffer` untouched.

After the fix, the copy block in both functions should look like:
```swift
        context.draw(cgImage, in: canvasRect)
        return pixelBuffer
    }
```

---

## Fix 2 — Hard-cap short slideshow to 5 photos (MemoryCreationView.swift)

The user wants a maximum of 5 photos in the Short Slideshow, for all users (no premium distinction).

### Change A — `maxPhotos` computed property (around line 497):

Find:
```swift
    private var maxPhotos: Int { subscriptionManager.hasPremiumEntitlement ? 10 : 5 }
```
Replace with:
```swift
    private var maxPhotos: Int { 5 }
```

### Change B — confirmation dialog button label (around line 118):

Find:
```swift
                Button("Short Slideshow (up to 10 photos)") { showingCreationSlideshow = true }
```
Replace with:
```swift
                Button("Short Slideshow (up to 5 photos)") { showingCreationSlideshow = true }
```

---

## Files to modify

| File | Changes |
|------|---------|
| `MemoryInk/Services/SlideshowService.swift` | Remove 4 lines (2 per function) |
| `MemoryInk/Features/MemoryCreation/MemoryCreationView.swift` | 2 line changes |

**Do NOT touch any other file. Do NOT delete Package.resolved.**

---

## Constraints

- [ ] Y-flip lines (`translateBy` + `scaleBy`) must be removed from BOTH `renderFrame` AND `renderImageFrame` — not just one
- [ ] `context.draw(cgImage, in: canvasRect)` must remain in both functions — do NOT remove it
- [ ] `maxPhotos` must return the literal `5` — no conditional, no ternary
- [ ] `@State private var subscriptionManager` and all other state in `CreationSlideshowSheet` must remain unchanged
- [ ] Do NOT touch `SlideshowPickerView.swift` — it has its own separate `maxSelectable` logic that is not changed here
- [ ] Do NOT delete Package.resolved

---

## Success criteria

```bash
# No translateBy or scaleBy anywhere in SlideshowService
grep -n "translateBy\|scaleBy" MemoryInk/Services/SlideshowService.swift
# must return: no output

# context.draw still present twice
grep -c "context\.draw(cgImage" MemoryInk/Services/SlideshowService.swift
# must return: 2

# maxPhotos returns 5
grep -n "maxPhotos" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift
# must show: private var maxPhotos: Int { 5 }

# button label updated
grep -n "up to 5 photos\|up to 10 photos" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift
# must show "up to 5 photos" only, no "up to 10 photos"

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

## Expected response format

```
### Planned Changes
- SlideshowService.swift — Y-flip removed from renderFrame and renderImageFrame copy step
- MemoryCreationView.swift — maxPhotos hard-capped at 5, button label updated

### Summary
- Files changed: [list]
- Behavior change: [1 sentence per file]
- Not verified: [list]
- Needs human approval: no
```
