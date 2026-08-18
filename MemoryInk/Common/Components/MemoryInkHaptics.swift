import UIKit

/// Centralized haptic feedback so screens fire consistent, deliberate haptics instead of
/// each hand-rolling `UIImpactFeedbackGenerator`/`UISelectionFeedbackGenerator` per call site.
/// Timeline, TimelineCard, MemoryDetail, CardBrowse, and MoodPicker already do this inline —
/// other screens (Settings, Calendar, Slideshow, Subscription, Recap, On This Day, Yearly
/// Review) had none at all. New call sites should use these instead of instantiating a
/// generator directly.
enum MemoryInkHaptics {
    /// Light tap — navigation, opening something, a minor toggle.
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium tap — a committed, more consequential action (sign out, delete, submit, purchase).
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Selection change — segmented pickers, filters, mode toggles, month/tab switches.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
