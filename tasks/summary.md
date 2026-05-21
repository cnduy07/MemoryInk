## Completed
- Added launch sync after entitlement refresh in `MemoryInkApp`.
- Added foreground sync when the scene becomes active in `MemoryInkApp`.
- Added post-save metadata sync when the timeline entry count changes.
- Added one-time automatic paywall sheet presentation when paywall eligibility first becomes true.
- Added a top-right Close button to `SubscriptionView`.

## Build Result
- Fail: the required `xcodebuild -project MemoryInk.xcodeproj -scheme MemoryInk -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -20` command failed during SwiftPM package resolution for `purchases-ios-spm` before app sources compiled.
- Error observed: `unable to make temporary file: Operation not permitted` while loading the RevenueCat package manifest.
- Additional verification attempt with writable derived data failed because network is restricted and Xcode could not clone `https://github.com/RevenueCat/purchases-ios-spm.git`.
- No source compile errors were reached or fixed.

## Files Changed
- `MemoryInk/App/MemoryInkApp.swift`
- `MemoryInk/Features/Timeline/TimelineView.swift`
- `MemoryInk/Features/Subscription/SubscriptionView.swift`
- `tasks/summary.md`

## Constraint Check
- Confirmed: no new packages.
- Confirmed: no CoreData changes.
- Confirmed: no pricing changes.
- Confirmed: no photo data sent anywhere.
