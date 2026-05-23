# Task V: iPad font scale and Timeline card width

**Date:** 2026-05-23
**Phase:** Phase 3 — Monetization & Sync
**Priority:** High
**Estimated scope:** Small (2 files, surgical edits)

---

## Context

After Task U raised `MemoryCreationView`'s content width to 560pt on iPad, two root causes of small iPad UI remain:

1. **`MemoryInkTypography`** — all 7 font sizes are hardcoded `static let` constants (12–36pt). These values are the same on every device. On iPad the fonts look phone-sized.

2. **`TimelineView.layoutMetrics()`** — `cardMaxWidth` and `detailMaxWidth` are both capped at 430pt regardless of device. On an iPad Air (820pt wide) the Timeline card fills only 53% of the screen — text appears in a narrow column surrounded by empty space.

---

## Objective

iPad users see comfortably scaled fonts app-wide, and the Timeline card column fills a sensible fraction of the iPad screen. iPhone behavior is unchanged.

---

## Files to modify

| File | Action | Reason |
|------|--------|--------|
| `MemoryInk/Common/Theme/Typography.swift` | modify | Convert static lets to computed vars with iPad scale |
| `MemoryInk/Features/Timeline/TimelineView.swift` | modify | Lift 430pt card cap to 580pt on iPad |

**Do NOT touch:** `MemoryCreationView.swift`, `TimelineCard.swift`, any onboarding file, `MoodType.swift`, `Package.resolved`, any Service or Model file.

---

## Implementation spec

### Fix 1 — Typography.swift: iPad-adaptive font sizes

**Current file (full):**
```swift
import SwiftUI

enum MemoryInkTypography {
    static let title = Font.system(size: 36, weight: .semibold, design: .default)
    static let eyebrow = Font.system(size: 12, weight: .medium, design: .default)
    static let subtitle = Font.system(size: 15, weight: .regular, design: .default)
    static let narrative = Font.system(size: 18, weight: .medium, design: .default)
    static let narrativeCompact = Font.system(size: 17, weight: .medium, design: .default)
    static let timestamp = Font.system(size: 12, weight: .regular, design: .default)
    static let badge = Font.system(size: 12, weight: .medium, design: .default)
}
```

**Replace with:**
```swift
import SwiftUI
import UIKit

enum MemoryInkTypography {
    private static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var title: Font {
        .system(size: isPad ? 44 : 36, weight: .semibold, design: .default)
    }
    static var eyebrow: Font {
        .system(size: isPad ? 13 : 12, weight: .medium, design: .default)
    }
    static var subtitle: Font {
        .system(size: isPad ? 17 : 15, weight: .regular, design: .default)
    }
    static var narrative: Font {
        .system(size: isPad ? 20 : 18, weight: .medium, design: .default)
    }
    static var narrativeCompact: Font {
        .system(size: isPad ? 19 : 17, weight: .medium, design: .default)
    }
    static var timestamp: Font {
        .system(size: isPad ? 14 : 12, weight: .regular, design: .default)
    }
    static var badge: Font {
        .system(size: isPad ? 14 : 12, weight: .medium, design: .default)
    }
}
```

**Rules:**
- `UIKit` import is required for `UIDevice`.
- All 7 existing names (`title`, `eyebrow`, `subtitle`, `narrative`, `narrativeCompact`, `timestamp`, `badge`) must remain — same names, same weights, same `design: .default`. Only the sizes are conditional.
- The private `isPad` helper must be a computed `static var`, not a `static let`, because it reads a runtime value.
- Do NOT add any new font styles. Do NOT change any weight or design parameter.
- iPhone sizes (the `false` branch) must be byte-for-byte identical to what they are today.

---

### Fix 2 — TimelineView.swift: card and detail max width for iPad

In `layoutMetrics(for:)` (near the bottom of the file), there are two lines that cap width at 430pt. Both must be changed.

**Current lines:**
```swift
        let regularWidth = finiteDimension(min(availableWidth, 430))
```
and
```swift
        let detailWidth = finiteDimension(min(availableDetailWidth, isCompact ? 304 : 430))
```

**Replace with:**
```swift
        let regularWidth = finiteDimension(min(availableWidth, viewportWidth > 700 ? 580 : 430))
```
and
```swift
        let detailWidth = finiteDimension(min(availableDetailWidth, isCompact ? 304 : (viewportWidth > 700 ? 580 : 430)))
```

**Why 580?** The Timeline needs some breathing room on both sides even on iPad (it is not full-bleed), so 580pt on an 820pt iPad Air leaves 120pt of margin — appropriate for a journaling app. The 560pt onboarding cap stays at 560 (different file, not touched).

**Rules:**
- Only these 2 lines change. Do NOT touch `compactWidth` (304), `isCompact` logic, padding values, or any other metric.
- The `> 700` threshold matches what was already used in `MemoryCreationView.swift` — keep it consistent.

---

## Constraints

- [ ] No new Swift Packages
- [ ] iPhone font sizes must be identical to today (36, 12, 15, 18, 17, 12, 12)
- [ ] `MemoryCreationView.swift` must NOT be modified
- [ ] `TimelineCard.swift` must NOT be modified
- [ ] No new font styles added to Typography
- [ ] No weight or design parameters changed in Typography

---

## Success criteria

```bash
# Fix 1: static let is gone — all are now static var
grep -n "static let" MemoryInk/Common/Theme/Typography.swift
# must return: no output

# Fix 1: isPad helper present
grep -n "isPad" MemoryInk/Common/Theme/Typography.swift
# must return: 8 lines (1 declaration + 7 usages)

# Fix 1: iPad sizes correct
grep -n "isPad ? 44" MemoryInk/Common/Theme/Typography.swift
grep -n "isPad ? 20" MemoryInk/Common/Theme/Typography.swift
grep -n "isPad ? 14" MemoryInk/Common/Theme/Typography.swift
# must each return: 1 match

# Fix 2: Timeline uses 580 on iPad
grep -n "580" MemoryInk/Features/Timeline/TimelineView.swift
# must return: 2 matches (cardMaxWidth and detailMaxWidth)

# Fix 2: compactWidth still 304
grep -n "304" MemoryInk/Features/Timeline/TimelineView.swift
# must return: 2 matches (unchanged)

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

## Out of scope

- Settings, Recap, OnThisDay, MemoryDetail views — not touched in this task
- Spacing values (MemoryInkSpacing) — not changed
- Dynamic Type / accessibility size classes
- Any Supabase, RevenueCat, or auth work

---

## Expected Codex response format

```
### Planned Changes
- Typography.swift modify — convert static lets to computed vars with isPad branching
- TimelineView.swift modify — lift 430pt cap to 580pt on iPad

### Code
[Code here]

### Summary
- Files changed: [list]
- Behavior change: [1 sentence per fix]
- Not verified: [list]
- Needs human approval for next step: no
```
