### Planned Changes

**B1 — On This Day+ / richer milestones**
- `Services/MilestoneService.swift` modify — count-only → ordered journey-milestone table
- `Services/OnThisDayService.swift` modify — year-grouped results + journey day number
- `Persistence/JournalEntryRepository.swift` modify — computed `firstEntryDate`
- `Features/OnThisDay/OnThisDayView.swift` modify — year comparison strip + per-year sections
- `Features/Timeline/TimelineView.swift` modify — new milestone API, checked on `.task` too

**B2 — Shareable memory card themes**
- `Common/Components/MemoryShareRenderer.swift` modify — `MemoryShareTheme` + framed layout
- `Common/Components/MemoryShareCardSheet.swift` create — preview + theme picker + share
- Timeline / MemoryDetail / CardBrowse / MemoryCreation modify — all four share paths unified

**B3 — Local backup / export**
- `Services/ExportService.swift` create — metadata-only JSON backup
- `Features/Settings/SettingsView.swift` modify — "Your Data" section

**B5 — Calendar mood heatmap**
- `Features/Calendar/CalendarViewModel.swift` modify — `intensity(for:in:)`
- `Features/Calendar/CalendarView.swift` modify — density cells + legend

**B4 — Face ID app lock** *(approved this session)*
- `Services/AppLockService.swift` create, `Features/AppLock/AppLockView.swift` create
- `App/MemoryInkApp.swift` modify — lock overlay + lock on background
- `Features/Settings/SettingsView.swift` modify — "Privacy" section
- `MemoryInk/Info.plist` modify — `NSFaceIDUsageDescription` (**gitignored**)

**B6 — Widgets** *(approved this session — snapshot approach)*
- `Models/WidgetSnapshot.swift` create — shared between both targets
- `Services/WidgetSnapshotService.swift` create — writes snapshot + thumbnail to the App Group
- `MemoryInkWidget/` create — bundle, widget views, Info.plist, entitlements
- `MemoryInk/MemoryInk.entitlements` modify — App Group added
- `MemoryInk.xcodeproj/project.pbxproj` modify — new extension target, phases, configs, embed phase

### Code
```swift
// MilestoneService.swift — the moment is chosen, not just matched
let reached = Self.milestones.filter { $0.isReached(entryCount, dayNumber, years) }
guard let deepestUnshown = reached.last(where: { !hasShown($0) }) else { return nil }

// Mark every reached milestone as shown, not just the one being surfaced, so a user
// who returns after a long gap gets one quiet moment instead of a queue of toasts.
reached.forEach { markShown($0) }
return deepestUnshown.message
```

```swift
// ExportService.swift — file name only, never the image
let name = (entry.photoPath as NSString).lastPathComponent
photoFileName = name.isEmpty ? nil : name
```

```swift
// WidgetSnapshotService.swift — the widget gets a snapshot; the store stays put
guard let containerURL = WidgetSharedStore.containerURL,
      let snapshotURL = WidgetSharedStore.snapshotURL else { return }
```

### Summary
- **Files changed:** 15 modified + 9 new source/config files + the widget target in
  `project.pbxproj`, plus the three `tasks/` docs. `git status` shows nothing outside that set.
- **Behavior change:** Part B of the v2 plan, complete. Richer journey milestones and a
  year-over-year On This Day; a share-card preview with four themes; a free metadata-only export;
  a density heatmap on the calendar; an optional Face ID lock; and Home/Lock Screen widgets fed by
  a snapshot file.
- **Checks run:**
  - Real `xcodebuild … build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED** (four times across the batch)
  - **Both targets' `SwiftFileList`s inspected** — every new file is genuinely compiled into the
    target that should have it, and `WidgetSnapshot.swift` into both. This is the Part A failure
    mode, so it's checked directly rather than assumed.
  - `.appex` confirmed embedded at `MemoryInk.app/PlugIns/` with extension point
    `com.apple.widgetkit-extension`; widget bundle id `com.memoryink.app.MemoryInkWidget`
  - App Group `group.com.memoryink.app` verified identical across both entitlements files and the code
  - `NSFaceIDUsageDescription` confirmed in the **built** app's Info.plist, not just the source
  - 21 assertions against the real `ExportService.swift` → all pass, including: photo **file name
    only** with no directory structure anywhere in the output, no image bytes, and no
    `gps`/`latitude`/`longitude`/`exif` field
  - 16 assertions against the real `MilestoneService.swift` → all pass, including legacy-key respect
  - `plutil -lint` on `project.pbxproj` after every edit
  - **Caught and fixed two of my own bugs mid-task:** (1) the share preview re-rendered a 2160×2160
    image on every SwiftUI body pass — now rendered once per theme; (2) my first pbxproj patch
    script used a 2-tab anchor that also matched 4-tab child references, silently filing four files
    into "Preview Content" and four build entries into the Resources phase instead of Sources. The
    first build caught it; every placement was then re-audited programmatically.
- **Not verified:**
  - **Nothing here has been seen running** — no simulator or device pass. The themed share cards
    (hand-placed drawing coordinates) and the widget layouts are the least certain.
  - The widget cannot actually read anything until the App Group is enabled in your developer
    account — until then it shows its empty state. That's a portal config step, not code.
  - `.classic` share output being unchanged is established by code inspection, not an image diff.
  - Face ID flow untested against real biometrics; simulator/device pass needed.
  - The lock overlay's interaction with an already-presented sheet is unverified.
- **Needs human approval for next step: no.** Both approval checkpoints (B4's Info.plist string,
  B6's data-sharing approach) were cleared with you before that code was written. See
  `tasks/SESSION_HANDOFF.md` for the two manual config steps that are now yours.
