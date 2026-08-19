# Session Handoff — MemoryInk v2 Upgrade

> Multi-session progress tracker for the approved plan at `~/.claude/plans/nested-bouncing-ocean.md`.
> Claude Code keeps this current at all times and updates the "Ready to open a new session?"
> section whenever a full Part/Phase completes. Starting a new session on this plan? Read this first.

**Last updated:** 2026-08-19 (session 6 — v2 merged to `main` as 2.0; Part C planned)

---

## Status overview

| Part / Phase | Status |
|---|---|
| Milestone 1 / Part A — Visual Refresh | ✅ **Complete — 9 of 9, committed `1ffa9eb`** |
| Milestone 2 / Part B — New Features | ✅ **Complete — 6 of 6, committed `cf4c952`** |
| Device-pass fixes | ✅ **Pass cleared 2026-08-19 — 1 bug found and fixed (BUGS §9.4)** |
| Release of v2 | 🟡 **Merged to `main` as 2.0 build 5, pushed. App Store submission is yours.** |
| Milestone 3 / Part C — Cinematic Dark rebuild | 📋 **Planned, not started — [`PART_C_PLAN.md`](PART_C_PLAN.md)** |

**v2 is done and merged.** `main` carries the full v2 upgrade at version 2.0 (build 5), pushed to
GitHub. What remains for v2 is App Store submission, which only you can do.

**Next milestone is Part C — a Cinematic Dark UI/UX rebuild**, planned in
[`PART_C_PLAN.md`](PART_C_PLAN.md) and shipping separately as v3. It does not block the v2
submission and should not delay it.

---

## ⚠️ Manual steps owed by you

**→ See [`tasks/MANUAL_TODO.md`](MANUAL_TODO.md)** — the running list across all parts and
sessions, with checkboxes, why each matters, and how to verify it worked. Currently open:

- ✅ ~~Enable App Group `group.com.memoryink.app`~~ — **done, confirmed 2026-08-19.** The widget
  App ID was auto-created by Xcode's automatic signing; the group is registered and ticked.
- 🔴 Back up the two gitignored Info.plist keys (`UIAppFonts`, `NSFaceIDUsageDescription`)
- 🟡 The Spectral serif at title sizes (A.4) — the one visual item not yet confirmed
- ✅ ~~Device pass on Part B~~ — **done 2026-08-19.** Face ID, themed share cards, sharing,
  On This Day+, dark mode incl. the calendar heatmap, and the detail overlay all confirmed working.

---

## Part A — Visual Refresh (done, committed `1ffa9eb`)

All 9 items shipped and build-verified; details in git history (`e18c837`, `1ffa9eb`).

---

## Part B — New Features (done, uncommitted)

| # | Item | Status |
|---|------|--------|
| B1 | On This Day+ / richer milestones | ✅ Done — build-verified + 16 unit assertions |
| B2 | Shareable memory card themes | ✅ Done — build-verified |
| B3 | Local backup / export | ✅ Done — build-verified + 21 assertions incl. privacy |
| B5 | Calendar mood-heatmap | ✅ Done — build-verified |
| B4 | Face ID app lock | ✅ Done — build-verified (approved this session) |
| B6 | Home/Lock Screen widgets | ✅ Done — build-verified (approved this session, snapshot approach) |

### What each one does

- **B1** — Milestones went from "fires on an exact entry count" to 15 one-off journey moments:
  counts (10→500), days since the first memory (30/100/500/1000), anniversaries (1–5 years).
  Thresholds are `>=` so nothing can be missed; when several land at once only the deepest shows.
  Existing `milestone_shown_*` keys are honoured. Also now checked on app open, not just on save —
  a day-count moment arrives with time passing. On This Day groups by year with an "Across the
  years" strip and a "Day N" chip.
- **B2** — Sharing opens a preview with four themes (Classic + three `BackgroundScene` gradients
  that only the slideshow exporter could show before). Themed cards use a framed layout so the
  theme is visible even with a photo. Classic is unchanged and remains the default. All four share
  entry points now go through one component.
- **B3** — Settings → Your Data → "Export my memories" writes a dated JSON backup for Files/Mail.
  Free for everyone. Photo **file names** only.
- **B5** — Calendar cells are mood-tinted by density in five steps instead of a 6pt dot, with a legend.
- **B4** — Optional Face ID / Touch ID / passcode lock, off by default, toggled in Settings →
  Privacy. Locks on backgrounding; starts locked so the journal never flashes at launch.
- **B6** — Small, medium, and two Lock Screen widget families showing the latest memory's mood,
  thumbnail, snippet, and day count.

### How B6 works (the decision you made)

The widget reads a **snapshot file**, not the journal. The app writes a small JSON plus one
thumbnail copy into the App Group container whenever entries change or the app backgrounds; the
widget reads that. **The Core Data store never moves and is never migrated** — existing journals
are untouched, which was the whole point of choosing this over relocating the store.

---

## Work not yet committed

**The hero-transition fix** (2 Swift files + 3 docs) on `memoryink-v2-part-b`, per "commit only
when asked." Part A and Part B are both already committed (`1ffa9eb`, `cf4c952`, `9eadfab`).

---

## ▶ Ready to open a new session?

**Yes — v2 is closed out and Part C is a fresh body of work with its own plan.** This session
carried the v2 device pass and release; Part C is a full milestone that will want its own context.

Suggested label: `memoryink-v3-part-c`. Kickoff prompt:

> "Start Part C of MemoryInk per tasks/PART_C_PLAN.md — the Cinematic Dark UI/UX rebuild, shipping
> as v3. v2 is already merged to main as 2.0 build 5. Branch off main as memoryink-v2-part-c and
> begin with C.1, the dark-first palette rewrite in Colors.swift."

Two things in the plan need your answer before C.1 lands — whether light mode stays (I assume yes)
and whether `AGENTS.md`'s "warm neutrals, film tones" identity line may be rewritten. Both are
written up under **Decisions** in the plan.

**Fixed this session:**
- Timeline → detail overlay hero transition — `matchedGeometryEffect` pinned the overlay photo to
  the source card's on-screen position, because the Timeline stays mounted behind the overlay so
  the geometry source never went away. Replaced with the plain scale + fade transition the overlay
  already had. Verified by a real `xcodebuild` (**BUILD SUCCEEDED**) and by `grep` confirming zero
  `matchedGeometryEffect`/`Namespace` references remain. **Not verified on device** — that's in
  `MANUAL_TODO.md` under 🟡.
