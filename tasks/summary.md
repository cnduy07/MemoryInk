## Completed
- Added the `.browse` route and wired it from the timeline header.
- Created `CardBrowseView` with a full-screen stacked card deck, left/right swipe gestures, favorite-on-right-swipe, share action, and end state.
- Added the new Browse source file to the Xcode project.
- Aligned `MemoryDetailView` with the shared `ShareSheet(items:)` component to resolve the duplicate `ShareSheet` compile conflict.

## Files Changed
- `MemoryInk/App/AppRouter.swift`
- `MemoryInk/Features/Browse/CardBrowseView.swift`
- `MemoryInk/Features/Timeline/TimelineView.swift`
- `MemoryInk/Features/MemoryDetail/MemoryDetailView.swift`
- `MemoryInk.xcodeproj/project.pbxproj`
- `tasks/summary.md`

## Behavior Change
- Timeline shows a Browse button in the header icon strip when there are 5 or more entries.
- Browse mode presents memories as a Tinder-style deck; right swipe favorites and advances, left swipe skips and advances, and the share button renders the current memory share image.

## Checks Run
- `xcodebuild -project MemoryInk.xcodeproj -scheme MemoryInk -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -20`
- `TMPDIR=/private/tmp xcodebuild -project MemoryInk.xcodeproj -scheme MemoryInk -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -80`
- `TMPDIR=/private/tmp CLANG_MODULE_CACHE_PATH=/private/tmp/clang-module-cache xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios17.0-simulator -typecheck $(rg --files MemoryInk -g '*.swift')`

## Build Result
- The required `xcodebuild` command did not reach app source compilation.
- Failure observed during SwiftPM package resolution for `purchases-ios-spm`: `unable to make temporary file: Operation not permitted`.
- The command also reported CoreSimulatorService connection refusal in this sandbox.
- Full Swift source typecheck passed after fixing the shared `ShareSheet` conflict. Remaining output was existing iOS 17 `onChange(of:perform:)` deprecation warnings.

## Not Verified
- Full Xcode build, because package resolution failed before source compilation.
- Runtime card swipe behavior in Simulator.

## Next Step Needs Approval
- No.
