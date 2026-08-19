# Summary — Fix the Timeline → detail overlay hero transition

**Date:** 2026-08-19 · **Branch:** `memoryink-v2-part-b` · **Task spec:** `tasks/current-task.md`

---

## Files changed

| File | Change |
|---|---|
| `MemoryInk/Features/Timeline/TimelineCard.swift` | Removed `.timelineHeroEffect(...)` from `imageArea`, the `timelineHeroEffect` private `View` extension, and the `namespace` property + init parameter |
| `MemoryInk/Features/Timeline/TimelineView.swift` | Removed `@Namespace private var cardNamespace` and the `namespace:` argument at all three `TimelineCard` call sites (list, grid, detail overlay) |
| `docs/BUGS_AND_FIXES.md` | Added §9.4 (bilingual) + a new row in the patterns table + an interview-story entry |
| `docs/FEATURES_AND_TASKS.md` | Corrected two now-stale "matched-geometry" claims; added a changelog row |
| `tasks/MANUAL_TODO.md` | Archived the Part A motion item at your request; opened a specific re-verification item for the rewritten transition |
| `tasks/SESSION_HANDOFF.md` | Marked the project as being in its device-pass phase; recorded this fix |

## Behavior change

Tapping a Timeline card now opens the detail overlay laid out by its own layout (centred, 4:5 photo
at `detailMaxWidth`) regardless of where the source card sat on screen, animating in with the calm
scale + opacity transition the overlay already declared. Previously the overlay's photo was pinned
to the source card's frame with no animation at all.

## Root cause (short)

`matchedGeometryEffect` hands the source view's frame to the non-source view *for as long as the
source exists*. The Timeline is never unmounted when the overlay opens — it stays in the same
`ZStack`, blurred and `allowsHitTesting(false)` — so the collapsed card remained the live geometry
source and permanently overrode the overlay card's own layout. Full write-up in
`docs/BUGS_AND_FIXES.md` §9.4.

## Checks run

- `xcodebuild -project MemoryInk.xcodeproj -scheme MemoryInk -destination 'generic/platform=iOS' -configuration Debug build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED**
- `grep -rn "matchedGeometryEffect\|Namespace" --include="*.swift" .` → zero hits
- Read the full Swift diff: 24 lines removed, nothing added; no other behavior touched
- Confirmed `isExpanded` is still used (shadow, hit-testing, accent height) so no dead parameter remains
- Confirmed `imageArea`'s `.aspectRatio(4/5, .fit)` gives the expanded card a correct size now that the geometry override is gone

## Not verified

- **On-device appearance of the fixed transition.** No simulator or Xcode GUI here. Logged in
  `tasks/MANUAL_TODO.md` under 🟡 with the exact check: tap a card near the top of the screen, then
  one near the bottom — the overlay's photo must land in the same place both times.
- Reduce Motion behaviour of the transition (it routes through the existing `cinematicAnimation`,
  which already collapses to `.linear(duration: 0.01)`, but this was reasoned about, not seen).

## Next step needs approval

No. Nothing is committed — say the word and I'll commit this to `memoryink-v2-part-b`.
