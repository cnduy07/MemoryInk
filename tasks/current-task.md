# Task U: Fix 3 UX bugs — iPad content width, Done button position, tap-to-add-photo regression

**Date:** 2026-05-23
**Phase:** Phase 3 — Monetization & Sync
**Priority:** High
**Estimated scope:** Small (1 file, 3 targeted edits)

---

## Context

Three bugs found in `MemoryCreationView.swift` during QA on iPhone SE and iPad:

1. **iPad content too narrow** — `contentWidth` is capped at 430pt regardless of device. On iPad (768–1366pt wide) the creation form occupies less than half the screen width, looking phone-sized and cramped.

2. **Done button pushed off-screen on iPhone SE** — `MemorySavedSheet` uses an uncapped `Spacer()` to push the bottom section (AI text + Share + Done) as far down as possible. On iPhone SE (667pt screen) this sends the Done button to the very bottom edge, making it nearly unreachable.

3. **Tap-to-add-photo is a dead zone (regression from Task T)** — Task T removed `onTapGesture { showingPhotoActionSheet = true }` and `contentShape(Rectangle())` from `photoPreview` but did not replace them with a Menu. The empty-state card (showing "Tap to add a photo") looks interactive but does nothing when tapped.

---

## Objective

All three bugs fixed in `MemoryCreationView.swift` with no design changes on iPhone. On iPad, creation form is comfortably wide. On iPhone SE, Done button is always reachable. Tapping the empty photo card opens the photo-type menu.

---

## Files to modify

| File | Action | Reason |
|------|--------|--------|
| `MemoryInk/Features/MemoryCreation/MemoryCreationView.swift` | modify | All 3 fixes — see spec below |

**Do NOT touch:** `MemoryCreationViewModel.swift`, any onboarding file, `MoodType.swift`, `Package.resolved`, `AGENTS.md`.

---

## Implementation spec

### Fix 1 — iPad content width (line 36)

**Current (line 36):**
```swift
let contentWidth = finiteDimension(min(availableWidth, 430))
```

**Replace with:**
```swift
let contentWidth = finiteDimension(min(availableWidth, viewportSize.width > 700 ? 560 : 430))
```

**Why:** iPad logical widths start at 768pt; iPhones max at 430pt (iPhone 15 Pro Max). `> 700` reliably separates them. 560pt matches the onboarding max-width already in place.

Do NOT change any other layout values on this line or nearby lines.

---

### Fix 2 — Done button position in MemorySavedSheet (line 411)

**Current (line 411, inside `MemorySavedSheet` body VStack):**
```swift
            Spacer()
```

**Replace with:**
```swift
            Spacer(minLength: 0)
                .frame(maxHeight: 80)
```

**Why:** The uncapped `Spacer()` expands to fill all remaining sheet height. On iPhone SE (~577pt available) the bottom content (AI text 30pt + Share 56pt + Done 96pt = 182pt) gets pushed to position ~395pt from top, placing Done's bottom at exactly the screen edge. Capping at 80pt leaves Done ~115pt from the bottom on SE — comfortably in thumb reach. On larger iPhones (812pt+) the cap never activates so design is unchanged.

Do NOT change the Done button's `.frame(maxWidth: .infinity, minHeight: 44)`, `.padding(.top, 16)`, or `.padding(.bottom, 36)`.

---

### Fix 3 — Tap-to-add-photo in photoPreview (lines 250–263)

**Current (lines 250–263, the `else` branch inside the `ZStack` in `photoPreview`):**
```swift
                } else {
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
                }
```

**Replace with:**
```swift
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
```

**Why:** The `Menu` wraps the entire empty-state label so tapping anywhere in the card — not just the text — presents the picker options. `frame(maxWidth: .infinity, maxHeight: .infinity)` expands the label to fill the `ZStack`/`GeometryReader` bounds. `contentShape(Rectangle())` ensures transparent areas inside the label are tappable. The 4 options match the subtitle text ("Single · Collage · Slideshow · Mood"). Do NOT change the icon, text content, fonts, or colors.

---

## Constraints

- [ ] No new Swift Packages
- [ ] Do NOT modify `MemoryCreationViewModel.swift`
- [ ] Do NOT modify onboarding files
- [ ] `MoodType.swift` must not be touched
- [ ] Fix 1: only the `430` → conditional change on line 36; no other layout values changed
- [ ] Fix 2: only `Spacer()` → `Spacer(minLength: 0).frame(maxHeight: 80)`; Done button modifiers unchanged
- [ ] Fix 3: visual content (icon, text, fonts, colors) inside the VStack must be identical to what was there before; only the Menu wrapper is new

---

## Success criteria

```bash
# Fix 1: iPad width check present
grep -n "viewportSize.width > 700" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift
# must return: 1 match on line 36

# Fix 2: Spacer capped
grep -n "maxHeight: 80" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift
# must return: 1 match (inside MemorySavedSheet)

# Fix 3: Menu in photoPreview empty state
grep -n "Mood Backdrop" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift
# must return: 3 matches
# (1 in the "Add Photo" Menu — no-image branch, 1 in the "Change" Menu — has-image branch, 1 in the new photoPreview Menu)

# Fix 3: contentShape in photoPreview
grep -n "contentShape" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift
# must return: 1 match (inside photoPreview)

# No new state variables added
grep -n "@State private var" MemoryInk/Features/MemoryCreation/MemoryCreationView.swift | wc -l
# must return: 5 (same as before: showingScenePicker, showingLibraryPicker, showingCollagePicker, showingCreationSlideshow, showingSuccessSheet)

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

## Out of scope for this task

- Timeline, Settings, Recap, or any other screen — not investigated, not touched
- iPad layout for screens other than MemoryCreationView
- Font scaling for iPad
- Subscription or paywall changes

---

## Expected Codex response format

```
### Planned Changes
- MemoryCreationView.swift modify — Fix 1 (iPad width), Fix 2 (Spacer cap), Fix 3 (photoPreview Menu)

### Code
[Code here]

### Summary
- Files changed: [list]
- Behavior change: [1 sentence per fix]
- Not verified: [list]
- Needs human approval for next step: no
```
