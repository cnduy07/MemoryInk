import SwiftUI
import UIKit

/// Type scale for the Cinematic Dark direction (Part C, C.5).
///
/// Two changes from the pre-Part C scale, both about hierarchy:
///
/// **The serif moved onto the narrative.** Spectral used to dress the headers — "Timeline",
/// "Settings" — which are the least interesting words on any screen. The narrative is the one
/// piece of writing a person actually came back to read, so that is where the display face
/// belongs. Headers drop to the system face, which is what they were always doing anyway.
///
/// **The scale has real steps.** Before, almost everything sat between 12 and 20pt with the same
/// weight, so nothing led. The steps below are spread far enough apart to be told apart at a
/// glance, and the small end is deliberately quiet — timestamps and captions should recede on a
/// dark ground, not compete with the photograph above them.
enum MemoryInkTypography {
    private static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Bundled display serif.
    ///
    /// **SemiBold is the only weight in the bundle** (`MemoryInk/Fonts/Spectral-SemiBold.ttf`), so
    /// this takes no weight argument. `Font.custom` falls back to the system face *silently* when a
    /// name is missing, so asking for `Spectral-Regular` here would not fail loudly — the serif
    /// would simply disappear from the app and everything would look like plain system text. Sizes
    /// below are chosen for a semibold face; adding a lighter weight is a manual task (see
    /// `tasks/MANUAL_TODO.md`) because font files also need an `Info.plist` entry, and that file
    /// is gitignored.
    ///
    /// The fallback still matters for a fresh clone with no `UIAppFonts` key: the app must render
    /// in the system face rather than crash.
    private static func serif(size: CGFloat) -> Font {
        .custom("Spectral-SemiBold", size: size)
    }

    // MARK: - Display

    /// Screen titles. Lighter than before: at 34pt a semibold serif on near-black is heavy enough
    /// to feel like a headline rather than a title.
    static var title: Font {
        serif(size: isPad ? 42 : 34)
    }

    /// The scroll-collapsed header state.
    static var titleCompact: Font {
        serif(size: 27)
    }

    /// Section headings within a screen.
    static var heading: Font {
        .system(size: isPad ? 20 : 18, weight: .semibold)
    }

    /// Small all-caps label above a title. Tracking is applied at the call site with `.kerning`.
    static var eyebrow: Font {
        .system(size: isPad ? 12 : 11, weight: .semibold)
    }

    // MARK: - Reading

    /// The AI narrative — the reason the app exists, and now the only place the serif appears at
    /// reading size.
    ///
    /// Set a step smaller than a regular-weight serif would want, because the bundled face is
    /// semibold: at 19pt it reads as emphasis rather than as prose. Callers pair it with generous
    /// line spacing to keep it from feeling dense.
    static var narrative: Font {
        serif(size: isPad ? 20 : 18)
    }

    /// The narrative in a dense context (grid cards, widgets, previews).
    static var narrativeCompact: Font {
        serif(size: isPad ? 18 : 16)
    }

    /// Ordinary interface prose: settings rows, explanatory copy, button labels.
    static var body: Font {
        .system(size: isPad ? 17 : 16, weight: .regular)
    }

    /// Supporting prose under a heading.
    static var subtitle: Font {
        .system(size: isPad ? 16 : 15, weight: .regular)
    }

    // MARK: - Detail

    /// Timestamps and captions. Meant to recede.
    static var timestamp: Font {
        .system(size: isPad ? 13 : 12, weight: .regular)
    }

    /// Badge and chip text. Used uppercased with kerning.
    static var badge: Font {
        .system(size: isPad ? 12 : 10, weight: .semibold)
    }
}
