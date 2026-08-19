# Task: Milestone 2 (New Features) — B2 + B3 + B5, then B4 + B6

**Date:** 2026-08-19
**Plan:** MemoryInk v2 — Visual Refresh + Feature Upgrade, Part B items 2, 3, 5
**Priority:** High — closes the whole "no approval needed" block of Part B
**Estimated scope:** Large (2 new files, 9 modified)

> B1 (On This Day+ / richer milestones) shipped earlier today — see `tasks/summary.md`.
> B4 (Face ID) and B6 (widgets) are deliberately **not** in this task: each carries an approval
> checkpoint the plan says I must clear with the user first (B4 = new `NSFaceIDUsageDescription`
> Info.plist string; B6 = new WidgetKit target + App Groups entitlement + on-disk data layout).

---

## B2 — Shareable memory card themes

### Context
`MemoryShareRenderer` renders one fixed 1080×1080 card, called from **four** places
(Timeline, MemoryDetail, CardBrowse, MemoryCreation), each of which immediately dumps the result
into a bare `ShareSheet` with no preview and no choice. Meanwhile `BackgroundScene` holds 8
hand-tuned gradients used only by the slideshow exporter.

### Objective
The user picks a look before sharing, from a small set of themes reusing those gradients, and sees
what they're about to share.

### Design
- `MemoryShareTheme` (in `MemoryShareRenderer.swift`): `classic` + 3 scene-backed themes
  (Golden Hour, Night Ink, Parchment), each mapping to a `BackgroundScene.id` plus an ink colour.
- `MemoryShareRenderer.render(..., theme:)`, defaulting to `.classic`:
  - `.classic` → byte-for-byte today's output (full-bleed photo, or mood-tinted parchment). The
    existing look must not regress.
  - themed → "framed" layout: scene gradient background, photo inset in a rounded frame with a
    soft shadow, then mood badge / narrative / date / watermark in the theme's ink colour.
- `MemoryShareCardSheet` (new): live preview + theme chips + Share button. Replaces the raw
  `ShareSheet` at all four call sites so the experience is identical everywhere.
- Chosen theme persists via `@AppStorage("share_card_theme")`.

---

## B3 — Local backup / export

### Context
Premium users get Supabase metadata sync; nobody has a way to get their own words out of the app.
Trust-building and privacy-aligned — and per the plan it's for free *and* premium users.

### Design
- `ExportService` (new, `Services/`): builds a JSON document and writes it to a temp file
  `MemoryInk-Backup-YYYY-MM-DD.json`, returned as a `URL` for the share sheet ("Save to Files").
- Contents: `format_version`, `exported_at`, `entry_count`, and per entry — id, created_at (ISO
  8601), mood, narrative style, note, AI narrative, favourite flag, and the **local photo file
  name only**.
- **No photo bytes, no EXIF, no GPS, no thumbnails** — the file name is a local reference, exactly
  as the plan scopes it. The export is built entirely on-device; nothing is uploaded.
- Settings gets a "Your Data" section: an Export button and one warm line making the photo rule
  explicit to the user.

---

## B5 — Calendar mood heatmap

### Context
`CalendarView` day cells show a 6pt dot tinted by that day's first mood — no sense of density, and
a day with one memory looks the same as a day with six.

### Design
- `CalendarViewModel.intensity(for:in:)` → stepped 0…1 from the day's entry count.
- Day cell: mood-tinted background fill at that intensity (replacing the dot), day number kept
  legible, selection ring on top.
- A small legend under the grid ("Quieter → Fuller") so the colour ramp reads as intentional.

---

## Files touched

| File | Action |
|------|--------|
| `MemoryInk/Common/Components/MemoryShareRenderer.swift` | modify — `MemoryShareTheme` + themed "framed" layout; `.classic` path untouched |
| `MemoryInk/Common/Components/MemoryShareCardSheet.swift` | **create** — preview + theme picker + share |
| `MemoryInk/Services/ExportService.swift` | **create** — metadata-only JSON backup |
| `MemoryInk/Features/Timeline/TimelineView.swift` | modify — share via the new sheet |
| `MemoryInk/Features/MemoryDetail/MemoryDetailView.swift` | modify — share via the new sheet |
| `MemoryInk/Features/Browse/CardBrowseView.swift` | modify — share via the new sheet |
| `MemoryInk/Features/MemoryCreation/MemoryCreationView.swift` | modify — share via the new sheet (keeps its caption text) |
| `MemoryInk/Features/Settings/SettingsView.swift` | modify — "Your Data" export section |
| `MemoryInk/Features/Calendar/CalendarView.swift` | modify — heatmap cells + legend |
| `MemoryInk/Features/Calendar/CalendarViewModel.swift` | modify — `intensity(for:in:)` |
| `MemoryInk.xcodeproj/project.pbxproj` | modify — register the 2 new files (build file + file ref + group + Sources phase) |

**Do NOT touch:** CoreData model, `Info.plist`, subscription/paywall/entitlement code, sync code,
AI services.

---

## Constraints (AGENTS.md / CLAUDE.md)

- [x] No new Swift Package or external dependency — `UIGraphicsImageRenderer`, `JSONEncoder`, `UIActivityViewController` are all stock
- [x] No Core Data model change
- [x] No raw photo / EXIF / GPS leaves the device — the export carries file **names**, never bytes; share images are user-initiated and never uploaded by the app
- [x] No subscription pricing, entitlement, product ID, or paywall-timing change — export is free for everyone, which is what the plan specifies
- [x] No production API called
- [x] Copy stays warm and plain (no "backup successful", no jargon)

---

## Success criteria (binary)

- [x] `.classic` share output is unchanged from today's rendering
- [x] All four share call sites go through `MemoryShareCardSheet`; none constructs a bare `ShareSheet(items: [image])` any more
- [x] Theme choice survives app relaunch (`@AppStorage`)
- [x] Export writes a valid JSON file that round-trips through `JSONSerialization`, contains no photo bytes and no path outside a file name
- [x] Export works signed-out and unsubscribed (no entitlement gate)
- [x] Calendar cells show density, not a dot; empty days stay visually quiet
- [x] Both new files registered in `project.pbxproj` (build file + file ref + group + Sources) — the Part A failure mode
- [x] Real `xcodebuild … build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED**
- [x] `git diff --stat` shows exactly the files above

---

## Out of scope

- B4 (Face ID) and B6 (widgets) — both need a checkpoint from the user first
- Re-**importing** an export (restore) — export only for now; import is a bigger design question
- Theming the slideshow video export (different pipeline, not in the plan)

---

---

# Addendum — B4 + B6 (approved mid-session)

> Process note, honestly recorded: the spec above was written before implementing B2/B3/B5, per
> CLAUDE.md. B4 and B6 were approved partway through the same session, so this section was written
> **alongside** the work rather than strictly before it. The approval checkpoints themselves were
> cleared first, which was the part that actually mattered.

**Approvals obtained:** Face ID lock — "go ahead". Widget data sharing — **snapshot file**, not a
Core Data store move.

## B4 — Face ID / passcode app lock

- `Services/AppLockService.swift` (**create**) — `LAContext` with `.deviceOwnerAuthentication`
  (biometrics with passcode fallback). Off by default. Starts locked when enabled so the journal
  is never briefly visible at launch. A cancelled prompt is silent; no framework error text is
  ever shown to the user.
- `Features/AppLock/AppLockView.swift` (**create**) — the closed-book lock screen; prompts on
  appear so the common case is zero taps.
- `App/MemoryInkApp.swift` (modify) — overlay while locked; lock on `scenePhase == .background`.
- `Features/Settings/SettingsView.swift` (modify) — new "Privacy" section with the toggle, using
  the device's real biometry name ("Face ID" / "Touch ID" / "your passcode").
- `MemoryInk/Info.plist` (modify) — `NSFaceIDUsageDescription`. **Gitignored — user must back it up.**

## B6 — Home / Lock Screen widgets

Approach: **snapshot file**. The Core Data store is not moved, not shared, and not migrated.

- `Models/WidgetSnapshot.swift` (**create**) — the only type crossing between processes; compiled
  into **both** targets. Mood, day count, short snippet, thumbnail name, entry count. Nothing else.
- `Services/WidgetSnapshotService.swift` (**create**) — writes the snapshot + one thumbnail copy
  into the App Group container and reloads timelines. Silently no-ops when the App Group isn't
  reachable.
- `MemoryInkWidget/` (**create**) — `MemoryInkWidgetBundle.swift`, `MemoryInkWidget.swift`
  (small + medium + accessoryCircular + accessoryRectangular), `Info.plist`, entitlements.
- `MemoryInk/MemoryInk.entitlements` (modify) — App Group added alongside Sign in with Apple.
- `MemoryInk.xcodeproj/project.pbxproj` (modify) — new app-extension target, its build phases and
  configurations, the target dependency, and an Embed Foundation Extensions phase on the app.

### Success criteria

- [x] Widget target exists and `xcodebuild -list` shows it
- [x] Both targets compile their intended files (checked in each target's `SwiftFileList`)
- [x] `.appex` is embedded at `MemoryInk.app/PlugIns/` with the `com.apple.widgetkit-extension` point
- [x] App Group identifier identical in both entitlements files and in code
- [x] `NSFaceIDUsageDescription` present in the **built** app's Info.plist
- [x] Core Data store location unchanged — no migration anywhere in the diff
- [x] Real `xcodebuild … build` → **BUILD SUCCEEDED**

---

## Expected response format

Per AGENTS.md: Planned Changes / Code / Summary.
