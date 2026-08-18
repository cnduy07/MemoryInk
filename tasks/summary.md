### Planned Changes
- MemoryInk/Fonts/Spectral-SemiBold.ttf create — bundled display serif (SIL OFL 1.1, from Google Fonts)
- MemoryInk/Fonts/Spectral-OFL.txt create — license file kept alongside the font
- MemoryInk/Common/Theme/Typography.swift modify — `title` uses the serif; new `titleCompact` added
- MemoryInk/Features/Timeline/TimelineView.swift modify — compact header now uses `titleCompact` instead of a separate inline system-font literal
- MemoryInk.xcodeproj/project.pbxproj modify — registered font as a Resources-phase bundle resource, new `Fonts` group
- MemoryInk/Info.plist modify — added `UIAppFonts`; **not git-tracked, see caveat below**

### Code
```swift
// Typography.swift
private static func serifTitle(size: CGFloat) -> Font {
    .custom("Spectral-SemiBold", size: size)
}

static var title: Font { serifTitle(size: isPad ? 44 : 36) }
static var titleCompact: Font { serifTitle(size: 31) }
```

### Summary
- Files changed: `Spectral-SemiBold.ttf` + `Spectral-OFL.txt` (new), `Typography.swift`, `TimelineView.swift`, `project.pbxproj`, `Info.plist` (untracked)
- Behavior change: Every screen title/header that uses `MemoryInkTypography.title` (Calendar, Recap, YearlyReview, Settings' email sheet, Timeline greeting, Onboarding) now renders in a bundled warm serif (Spectral SemiBold) instead of the system sans-serif. Body text, labels, and timestamps are untouched — still system font, per the plan's legibility rule. Timeline's scroll-collapsed compact title was previously a separate hardcoded system-font literal that would've mismatched the new serif mid-scroll; it now shares the same font family at a smaller size via the new `titleCompact` style.
- **Caveat — action needed from you:** `MemoryInk/Info.plist` is deliberately gitignored (commit `4cef949`, it holds live API keys). I added the required `UIAppFonts` key to the file on disk and confirmed it works in a real build, but **this change will not be committed or travel with git** — only this machine's working copy has it. Please add the same key to wherever you keep your Info.plist backup (1Password/Notes, per that original commit's instructions), or the font will silently fall back to the system font on any fresh checkout:
  ```xml
  <key>UIAppFonts</key>
  <array>
      <string>Spectral-SemiBold.ttf</string>
  </array>
  ```
- Not verified: No simulator/visual pass — can't confirm on-screen rendering quality/kerning of the serif at each size without a device or simulator look.
- Checks run: Extracted the font's real PostScript name via `fontTools` (`Spectral-SemiBold`, matches the `Font.custom` call exactly). `plutil -lint` on `project.pbxproj` → OK. Real `xcodebuild ... build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED**. Directly inspected the *built* `.app` bundle in DerivedData: confirmed `Spectral-SemiBold.ttf` was physically copied in, and `UIAppFonts` is present in the built bundle's `Info.plist` — not just the source file.
- Needs human approval for next step: no code approval needed. **This closes Part A of Milestone 1 — 9 of 9 items done.** One manual step needed from you (above): back up the `UIAppFonts` Info.plist key outside git. See `tasks/SESSION_HANDOFF.md` for the Part B kickoff.
