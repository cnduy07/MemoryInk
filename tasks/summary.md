### Planned Changes
- MemoryInk/Common/Components/MemoryInkSwipeGesture.swift create — shared swipe-to-commit gesture logic
- MemoryInk/Common/Components/MemoryInkHaptics.swift create — centralized haptic helpers
- MemoryInk/Common/Components/MemoryInkMoodDistributionChart.swift create — reusable animated bar chart
- MemoryInk/Features/Timeline/TimelineCard.swift modify — consume shared swipe gesture
- MemoryInk/Features/Browse/CardBrowseView.swift modify — consume shared swipe gesture, remove redundant FlyDirection enum
- MemoryInk/Features/Settings/SettingsView.swift modify — haptics + press style on every button/toggle
- MemoryInk/Features/Calendar/CalendarView.swift modify — haptics + press style on nav/day-cell/list buttons
- MemoryInk/Features/Slideshow/SlideshowPickerView.swift modify — haptics + press style on pickers/selection/create
- MemoryInk/Features/Subscription/SubscriptionView.swift modify — haptics + press style on purchase/restore
- MemoryInk/Features/Recap/RecapView.swift modify — haptics on generate button; mood chart now shared component
- MemoryInk/Features/OnThisDay/OnThisDayView.swift modify — haptics + press style on entry card
- MemoryInk/Features/YearlyReview/YearlyReviewView.swift modify — haptics + press style; new mood-distribution section with reveal animation
- MemoryInk.xcodeproj/project.pbxproj modify — registered 3 new files with the build target

### Code
```swift
// MemoryInkSwipeGesture.swift — shared gesture builder
func memoryInkSwipeGesture(
    _ config: MemoryInkSwipeGestureConfig,
    onChanged: @escaping (CGSize) -> Void,
    onCommit: @escaping (MemoryInkSwipeDirection) -> Void,
    onCancel: @escaping () -> Void
) -> some Gesture { /* DragGesture + threshold-commit math, was duplicated in 2 files */ }
```
```swift
// MemoryInkHaptics.swift
enum MemoryInkHaptics {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
```
```swift
// MemoryInkMoodDistributionChart.swift — extracted from Recap, now also used by Yearly Review
struct MemoryInkMoodDistributionChart: View {
    struct Item { let mood: MoodType; let count: Int }
    let items: [Item]; let total: Int; var isVisible: Bool = true
    // label + spring-animated proportional bar + count, per row
}
```

### Summary
- Files changed: see Planned Changes above (12 modified, 3 created, 1 project file)
- Behavior change: (1) Swipe gestures on Timeline rows and Browse cards behave identically to before — pure internal refactor, same thresholds/coordinate spaces. (2) Settings, Calendar, Slideshow Picker, Subscription, Recap, On This Day, and Yearly Review now give haptic feedback and visible press-down feedback on every primary button/toggle — previously they had none at all. (3) Recap's mood chart is visually unchanged; Yearly Review gained a new "YOUR YEAR IN MOODS" section (only shown when premium content has at least one mood to show) with its own spring reveal animation — the first animation of any kind in that file.
- Scope note: A.8 originally called for merging EmotionGraphView (a line chart) with Recap's bar chart into one component. They're different chart types with no meaningfully shared code, so instead I extracted just the bar-chart pattern as its own reusable component and gave it a second real consumer (Yearly Review) — matches the plan's stated goal ("future screens get it for free") without forcing a bad abstraction.
- Checks run: `plutil -lint` on project.pbxproj after each of the 3 new-file registrations → OK every time. `comm` diff of on-disk `.swift` filenames vs pbxproj-referenced filenames → no orphans. Full real `xcodebuild -scheme MemoryInk -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO` run 3 times (after swipe-gesture change, after haptics sweep, after chart consolidation) → **BUILD SUCCEEDED** every time, zero errors.
- Not verified: No simulator/visual pass — haptics obviously can't be verified by a compiler at all (they either fire correctly at runtime or they don't), so this batch specifically would benefit from an actual on-device or simulator run to confirm feel/timing, on top of the usual visual check.
- Needs human approval for next step: no. Part A of Milestone 1 is now 7 of 9 items done — see `tasks/SESSION_HANDOFF.md` for exact status and what's left.
