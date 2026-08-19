# Task: Fix the Timeline → detail overlay hero transition (drop matchedGeometryEffect)

**Date:** 2026-08-19
**Phase:** Phase 3 — Monetization & Sync (bug fix on v2 Part A work)
**Priority:** High — user-visible breakage on the app's most-used interaction
**Estimated scope:** Small (2 Swift files + 2 docs)

---

## Context

Part A item A.5 wired a `matchedGeometryEffect` hero transition between a Timeline card's photo
and the same photo in the tap-to-expand detail overlay. On device it is wrong the instant it
appears: the overlay's photo is pinned to wherever the source card happened to be on screen
(card near the top → image at the top of the overlay; card near the bottom → image at the
bottom), with no animation at all.

Root cause: `matchedGeometryEffect` is a *hand-off* API. It expects exactly one source view to
exist at a time — the source's frame is handed to the non-source view, then the source goes away.
Here the Timeline is never unmounted: when `selectedMemory` is set, the scroll view stays in the
`ZStack` behind the overlay, only blurred and `.allowsHitTesting(false)`. So the collapsed card
(`isSource: true`) remains alive for the whole presentation, and the overlay card
(`isSource: false`) does not merely animate *from* that frame — it is permanently laid out *at*
that frame, overriding its own layout. That also explains the missing animation: there is no
transition happening, just an immediate geometry override.

## Objective

Tapping a Timeline card opens the detail overlay centred where the overlay's own layout puts it,
regardless of where the source card sat on screen, with the existing calm scale + opacity
transition (220–280ms, no bounce) playing on open and close.

---

## Files to modify

- `MemoryInk/Features/Timeline/TimelineCard.swift` — modify
  - Remove `.timelineHeroEffect(...)` from `imageArea` (used by **both** `listCard` and `gridBody`)
  - Remove the `timelineHeroEffect` private `View` extension
  - Remove the now-unused `namespace` stored property and its `init` parameter
- `MemoryInk/Features/Timeline/TimelineView.swift` — modify
  - Remove `@Namespace private var cardNamespace`
  - Remove `namespace:` from all three `TimelineCard(...)` call sites (list, grid, detail overlay)
- `docs/BUGS_AND_FIXES.md` — modify: add §9.4, bilingual (English line, Vietnamese in italics)
- `tasks/MANUAL_TODO.md` — modify: split the A.5 hero transition out of the Part A motion item so
  it is re-verified specifically after this fix

## Out of scope

- The grid path's tap target (grid cards push `.memoryViewer` / `.memoryDetail` routes, they never
  open this overlay) — not changed, only the unused `namespace` argument is dropped
- The overlay's layout, sizing, carousel buttons, swipe gesture, backdrop blur
- Any other `matchedGeometryEffect` in the app — there are none

---

## Success criteria (binary)

- [x] `grep -rn "matchedGeometryEffect\|Namespace" --include="*.swift" .` returns **zero** hits
- [x] The overlay `TimelineCard` still carries `.transition(.opacity.combined(with: .scale(...)))`
      and is still driven by `withAnimation(cinematicAnimation)` in `selectedMemory` set/clear
- [x] `xcodebuild ... build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED** (real build, not typecheck)
- [x] `docs/BUGS_AND_FIXES.md` has a §9.4 entry in the established bilingual format
- [x] `tasks/MANUAL_TODO.md` lists the reopened hero-transition check under 🟡 verification

## Needs human approval

No — no dependency, no Core Data change, no subscription/paywall/entitlement change, no new file.
Device verification of the result is the user's (added to MANUAL_TODO).
