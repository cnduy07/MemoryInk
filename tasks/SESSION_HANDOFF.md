# Session Handoff — MemoryInk v2 Upgrade

> Multi-session progress tracker for the approved plan at `~/.claude/plans/nested-bouncing-ocean.md`.
> Claude Code keeps this current at all times and updates the "Ready to open a new session?"
> section whenever a full Part/Phase completes. Starting a new session on this plan? Read this first.

**Last updated:** 2026-08-19 (session 5 — `memoryink-v2-part-b`)

---

## Status overview

| Part / Phase | Status |
|---|---|
| Milestone 1 / Part A — Visual Refresh | ✅ **Complete — 9 of 9, committed `1ffa9eb`** |
| Milestone 2 / Part B — New Features | ✅ **Complete — 6 of 6, build-verified, uncommitted** |

**The v2 plan's feature backlog is now fully implemented.** What remains is verification you have
to do yourself (a simulator/device pass), two manual config steps, and committing.

---

## ⚠️ Manual steps owed by you

**→ See [`tasks/MANUAL_TODO.md`](MANUAL_TODO.md)** — the running list across all parts and
sessions, with checkboxes, why each matters, and how to verify it worked. Currently open:

- ✅ ~~Enable App Group `group.com.memoryink.app`~~ — **done, confirmed 2026-08-19.** The widget
  App ID was auto-created by Xcode's automatic signing; the group is registered and ticked.
- 🔴 Back up the two gitignored Info.plist keys (`UIAppFonts`, `NSFaceIDUsageDescription`)
- 🟡 A simulator/device pass — **nothing in Part B has been seen running**, the themed share cards
  most of all. The widget is now unblocked and should show real data.

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

**All of Part B (B1–B6)** is implemented and verified but uncommitted, on branch
`memoryink-v2-part-a`, per "commit only when asked." Worth committing on a fresh
`memoryink-v2-part-b` branch to keep Part A's commit boundary clean. Say the word.

---

## ▶ Ready to open a new session?

**Yes — the plan's implementation is done.** Both milestones are complete; nothing is waiting on
another code task. A fresh session makes sense once you've done a simulator pass, to fix whatever
that pass turns up.

Suggested label: `memoryink-v2-polish`. Kickoff prompt:

> "MemoryInk v2 Parts A and B are implemented per tasks/SESSION_HANDOFF.md. I ran it in the
> simulator — here's what needs fixing: …"

If you'd rather keep going here, the most useful next things are: commit the work, or have me write
unit tests for the pieces that currently have none (the year grouping, calendar intensity, snapshot
building).
