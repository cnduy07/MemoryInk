## Completed
- Added `currentStreak` as a computed property on `JournalEntryRepository`.
- Removed the "Private timeline" eyebrow from the Timeline header icon row.
- Added Timeline memory count text below the subtitle.
- Added amber flame streak text when the current streak is at least 2 days.
- Replaced the plain Timeline "MemoryInk+" upgrade text with a styled "Go Premium" capsule.
- Added a bottom-left date stamp to Timeline grid cards.
- Increased Timeline mood badge tint opacity from 0.12 to 0.28.
- Changed Settings section card backgrounds to a warm paper gradient.
- Replaced raw missing-sync-configuration UI text with "Offline mode" and "Local only".
- Replaced the Settings plan row value with a styled capsule badge.

## Build Result
- Fail: the required `xcodebuild -project MemoryInk.xcodeproj -scheme MemoryInk -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -20` command failed before app source compilation during SwiftPM package resolution for `purchases-ios-spm`.
- Error observed: `unable to make temporary file: Operation not permitted` while loading the RevenueCat package manifest.
- Additional attempts with writable `TMPDIR`, derived data, package checkout, package cache, user cache, and module cache paths still failed before Swift source compilation; a derived-data-only retry also could not fetch `https://github.com/RevenueCat/purchases-ios-spm.git` because network access is restricted.
- No source compile errors were reached or fixed.

## Files Changed
- `MemoryInk/Persistence/JournalEntryRepository.swift`
- `MemoryInk/Features/Timeline/TimelineView.swift`
- `MemoryInk/Features/Timeline/TimelineCard.swift`
- `MemoryInk/Features/Settings/SettingsView.swift`
- `tasks/summary.md`
