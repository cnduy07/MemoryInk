# Task: Milestone 1 (Visual Refresh) — Swipe-Gesture, Haptics, Chart Consolidation

**Date:** 2026-08-18
**Plan:** MemoryInk v2 — Visual Refresh + Feature Upgrade, Milestone 1 / Part A items 6, 8, 9 (approved plan, implemented directly)
**Priority:** Medium
**Estimated scope:** Large (12 files + 3 new components)

---

## Context

Continuing Milestone 1 after the hero-transition/spacing-scale/hero-header task. This batch closes out three more Part A items: the swipe-gesture duplication between Timeline and Browse, the missing haptics/press-feedback across 7 screens, and the two independent chart implementations.

---

## Objective

1. `TimelineCard` and `CardBrowseView` share one gesture-recognition helper instead of two copies of the same drag/threshold math.
2. Settings, Calendar, Slideshow Picker, Subscription, Recap, On This Day, and Yearly Review all give haptic + press feedback on their primary interactive elements, matching Timeline's already-alive feel.
3. Recap's mood-distribution bar chart is a reusable component, and Yearly Review — which previously had zero animation anywhere in the file — now uses it too, with a real reveal moment.

---

## Files touched

| File | Action |
|------|--------|
| `MemoryInk/Common/Components/MemoryInkSwipeGesture.swift` | create — shared swipe-to-commit gesture logic |
| `MemoryInk/Common/Components/MemoryInkHaptics.swift` | create — centralized haptic helpers |
| `MemoryInk/Common/Components/MemoryInkMoodDistributionChart.swift` | create — reusable animated bar chart |
| `MemoryInk/Features/Timeline/TimelineCard.swift` | modify — consume shared swipe gesture |
| `MemoryInk/Features/Browse/CardBrowseView.swift` | modify — consume shared swipe gesture; removed now-redundant `FlyDirection` enum in favor of `MemoryInkSwipeDirection` |
| `MemoryInk/Features/Settings/SettingsView.swift` | modify — haptics + `MemoryInkPressStyle` on all buttons/toggle (main screen + `EmailAuthSheet`) |
| `MemoryInk/Features/Calendar/CalendarView.swift` | modify — haptics + press style on month nav, day cells, memory list rows |
| `MemoryInk/Features/Slideshow/SlideshowPickerView.swift` | modify — haptics + press style on mood/style pickers, grid selection, create button |
| `MemoryInk/Features/Subscription/SubscriptionView.swift` | modify — haptics + press style on plan purchase button, restore purchases |
| `MemoryInk/Features/Recap/RecapView.swift` | modify — haptics + press style on generate button; mood chart now uses shared component |
| `MemoryInk/Features/OnThisDay/OnThisDayView.swift` | modify — haptics + press style on entry card |
| `MemoryInk/Features/YearlyReview/YearlyReviewView.swift` | modify — haptics + press style on 3 buttons; new mood-distribution section with its own reveal animation (`moodBarsVisible`) |
| `MemoryInk.xcodeproj/project.pbxproj` | modify — registered the 3 new files (build file + file reference + group + sources phase, ×3) |

**Do NOT touch:** `SubscriptionManager`/`RevenueCatService` purchase logic itself, entitlement IDs, pricing, paywall trigger timing — only added a haptic call and a press-feedback button style around the existing purchase flow.

---

## Implementation spec (what was actually built)

### A.9 — Swipe-gesture consolidation
New `memoryInkSwipeGesture(_:onChanged:onCommit:onCancel:)` builds the `DragGesture` (configurable minimum distance, global-vs-local coordinate space, optional horizontal-dominance gate, prediction weight, threshold) and reports outcomes via closures. `TimelineCard` and `CardBrowseView` now call it with their exact original parameter values (20/0.22/global/horizontal-gate for Timeline; 10/0.25/local/no-gate for Browse) — a pure refactor, not a behavior change. `CardBrowseView`'s private `FlyDirection` enum was redundant with the new `MemoryInkSwipeDirection` and was removed in favor of it.

### A.6 — Haptics/press-feedback sweep
New `MemoryInkHaptics` enum (`.light()`, `.medium()`, `.selection()`) wraps `UIImpactFeedbackGenerator`/`UISelectionFeedbackGenerator` consistently. Applied across all 7 previously-silent screens: navigation/opening taps get `.light()`, mode/date/mood selection gets `.selection()`, and consequential actions (sign out, delete account, purchase, generate recap/review, create slideshow) get `.medium()`. Every button that had `.buttonStyle(.plain)` (or no style at all) now uses the existing `MemoryInkPressStyle()` for consistent press-down feedback.

### A.8 — Chart consolidation (scope note)
`EmotionGraphView` (a chronological mood-valence line chart) and Recap's mood-distribution bars are genuinely different chart types with different math — merging them into one component wouldn't share meaningful code, just make both harder to read. Instead: extracted the bar-chart pattern itself into `MemoryInkMoodDistributionChart`, reused it in Recap (replacing its inline version, zero behavior change), and gave Yearly Review — which had **no animation anywhere in the file** per the original design audit — a new "YOUR YEAR IN MOODS" section built on the same component, with its own spring-based reveal (`moodBarsVisible`, same pattern as Recap's `barsVisible`). `EmotionGraphView` is intentionally left as-is.

---

## Constraints (from AGENTS.md)

- [x] No new Swift Package or external dependency
- [x] No Core Data changes
- [x] No changes to subscription pricing, entitlement IDs, or paywall trigger logic
- [x] No changes to files outside the list above

---

## Success criteria

- [x] `TimelineCard.swift` and `CardBrowseView.swift` both call `memoryInkSwipeGesture` with their original threshold/prediction/space values preserved exactly
- [x] All 7 target screens have at least one `MemoryInkHaptics.*()` call and no remaining bare `.buttonStyle(.plain)` on a primary interactive control
- [x] `RecapView` and `YearlyReviewView` both render `MemoryInkMoodDistributionChart`; `EmotionGraphView` unmodified
- [x] All 3 new files registered in `project.pbxproj` (build file, file reference, group membership, sources phase) — verified via `comm` diff of on-disk `.swift` files vs files referenced in the pbxproj (no orphans)
- [x] `plutil -lint MemoryInk.xcodeproj/project.pbxproj` → OK
- [x] Real `xcodebuild -project MemoryInk.xcodeproj -scheme MemoryInk -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED**, run 3 times (once per sub-item) as each was completed, zero errors each time

---

## Out of scope for this task

- A.4 typography/custom font — still blocked on your font choice
- A.7 redesign of Settings/Slideshow Picker/Subscription visuals beyond backdrop+haptics (structural changes like Slideshow Picker's `NavigationView`→`NavigationStack`, entrance animations) — not started
- Any Part B feature work

---

## Expected response format

Per AGENTS.md:
```
### Planned Changes
- [Filename] [create / modify / delete] — short reason

### Code
[Code here]

### Summary
- Files changed: [explicit list]
- Behavior change: [1–2 sentence description]
- Not verified: [anything not tested or confirmed]
- Needs human approval for next step: [yes / no + reason if yes]
```
