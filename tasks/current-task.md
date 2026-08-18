# Task: Milestone 1 (Visual Refresh) — A.4 Typography (Bundled Display Serif)

**Date:** 2026-08-18
**Plan:** MemoryInk v2 — Visual Refresh + Feature Upgrade, Milestone 1 / Part A item 4 (approved plan, implemented directly)
**Priority:** Medium
**Estimated scope:** Small (1 new font resource, 3 files)

---

## Context

Last open item in Part A. User asked me to pick a free, license-clear font myself. Chose **Spectral** (Google Fonts, SIL Open Font License, by Production Type) — a warm, screen-optimized book serif designed for on-screen reading, fitting MemoryInk's "ink/parchment/journal" brand without the high-contrast drama of something like Playfair Display. Bundled as a static SemiBold weight only (matches the existing `.semibold` weight already used everywhere `MemoryInkTypography.title` appears — no variable-font axis handling needed).

## Objective

`MemoryInkTypography.title` (and Timeline's compact-header variant, which previously hardcoded a separate system-font literal) render in the bundled serif. Everything else — body text, labels, timestamps — stays `.system` for legibility, per the plan's explicit constraint.

---

## Files touched

| File | Action |
|------|--------|
| `MemoryInk/Fonts/Spectral-SemiBold.ttf` | create — font binary, downloaded from `google/fonts` GitHub repo (`ofl/spectral/`), SIL OFL 1.1 |
| `MemoryInk/Fonts/Spectral-OFL.txt` | create — license file, kept alongside the font for compliance (not bundled as an app resource) |
| `MemoryInk/Common/Theme/Typography.swift` | modify — `title` now uses `Font.custom("Spectral-SemiBold", ...)`; new `titleCompact` added |
| `MemoryInk/Features/Timeline/TimelineView.swift` | modify — compact header title now uses `MemoryInkTypography.titleCompact` instead of a separate inline system-font literal, so the font family doesn't visibly swap mid-scroll |
| `MemoryInk.xcodeproj/project.pbxproj` | modify — registered the font as a bundle *resource* (Copy Bundle Resources phase, not Sources) — new `Fonts` group mirroring the existing `Audio` group pattern |
| `MemoryInk/Info.plist` | modify — added `UIAppFonts` array with `Spectral-SemiBold.ttf` (**this file is gitignored** — see caveat below) |

**Do NOT touch:** any other `MemoryInkTypography` style (`eyebrow`, `subtitle`, `narrative`, `narrativeCompact`, `timestamp`, `badge`) — those stay system per the plan's "body text stays system" rule.

---

## Important caveat — Info.plist is not git-tracked

This repo deliberately excludes `MemoryInk/Info.plist` from git (commit `4cef949`, "contains Supabase anon key, RevenueCat key... keep a local backup"). The `UIAppFonts` addition is on disk and confirmed working in the built app bundle, but **it will not travel with any git commit/branch/clone** — it only exists on this machine's working copy. The user needs to add the same `UIAppFonts` key to wherever they keep their Info.plist backup (1Password/Notes per the original commit message) so it isn't lost.

---

## Constraints (from AGENTS.md)

- [x] No new Swift Package or external dependency — this is a bundled resource file, not a package
- [x] No Core Data changes
- [x] No changes to subscription pricing, entitlement IDs, or paywall trigger logic
- [x] No changes to files outside the list above
- [x] Font is SIL OFL 1.1 licensed (free for commercial app use, no attribution required in-app) — license file kept in-repo

---

## Success criteria

- [x] `Spectral-SemiBold.ttf` present in `MemoryInk/Fonts/`, registered in `project.pbxproj` Resources phase (not Sources)
- [x] `plutil -lint` on `project.pbxproj` → OK
- [x] `UIAppFonts` present in Info.plist; confirmed present in the **built app bundle's** `Info.plist` after a real build (not just source)
- [x] Confirmed `Spectral-SemiBold.ttf` physically copied into the built `.app` bundle
- [x] Confirmed the font's real PostScript name (`Spectral-SemiBold`, via `fontTools`) matches exactly what `Font.custom(...)` references
- [x] Real `xcodebuild ... build` → **BUILD SUCCEEDED**
- [x] Only `title`/`titleCompact` changed; no other typography style touched

---

## Out of scope for this task

- Any Part B feature work
- Adding more weights (Bold, Medium, Italic) — not used anywhere today; can add later if a real use case appears

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
