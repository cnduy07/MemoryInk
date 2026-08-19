import XCTest
import SwiftUI
import UIKit
@testable import MemoryInk

/// Contrast floors for the Part C *Cinematic Dark* palette.
///
/// These exist because the floors regress silently. Nothing about a too-dim timestamp makes the
/// app crash, fail to build, or look obviously wrong to someone who already knows what it says —
/// it just quietly stops being readable for everyone else. While tuning this palette by eye,
/// three separate rounds of values *looked* right and failed the arithmetic: 4.23:1, then 4.25:1,
/// then 4.28:1, each one caught only by measuring every text role against every surface it can
/// actually land on rather than against the standard background alone.
///
/// WCAG 2.1 thresholds used: 4.5:1 for body text, 3:1 for large text and graphical objects.
final class PaletteContrastTests: XCTestCase {

    private let light = UITraitCollection(userInterfaceStyle: .light)
    private let dark = UITraitCollection(userInterfaceStyle: .dark)

    /// Measured against `Raw` — the dynamic `UIColor` definitions — because that is what SwiftUI
    /// resolves when it renders `Color(Raw.x)`. Measuring the `Color` wrappers instead would test
    /// nothing: `UIColor(someColor)` flattens the adaptation away, which is how this suite found
    /// the export-pinning bug in the first place.
    private var surfaces: [(name: String, color: UIColor)] {
        [
            ("parchmentDeep", MemoryInkColors.Raw.parchmentDeep),
            ("parchment", MemoryInkColors.Raw.parchment),
            ("paper", MemoryInkColors.Raw.paper),
            ("paperWarm", MemoryInkColors.Raw.paperWarm)
        ]
    }

    private var textRoles: [(name: String, color: UIColor)] {
        [
            ("ink", MemoryInkColors.Raw.ink),
            ("secondaryInk", MemoryInkColors.Raw.secondaryInk),
            ("tertiaryInk", MemoryInkColors.Raw.tertiaryInk)
        ]
    }

    private var hues: [(name: String, color: UIColor)] {
        [
            ("amber", MemoryInkColors.Raw.amber), ("sunlit", MemoryInkColors.Raw.sunlit),
            ("sage", MemoryInkColors.Raw.sage), ("rosewood", MemoryInkColors.Raw.rosewood),
            ("mistBlue", MemoryInkColors.Raw.mistBlue), ("taupe", MemoryInkColors.Raw.taupe),
            ("teal", MemoryInkColors.Raw.teal), ("orchid", MemoryInkColors.Raw.orchid),
            ("gold", MemoryInkColors.Raw.gold), ("coral", MemoryInkColors.Raw.coral),
            ("ocean", MemoryInkColors.Raw.ocean), ("twilight", MemoryInkColors.Raw.twilight)
        ]
    }

    // MARK: - Tests

    func testTextRolesMeetAAOnEverySurfaceInBothAppearances() {
        for traits in [light, dark] {
            let appearance = traits.userInterfaceStyle == .dark ? "dark" : "light"
            for role in textRoles {
                for surface in surfaces {
                    let ratio = contrastRatio(role.color, surface.color, traits)
                    XCTAssertGreaterThanOrEqual(
                        ratio, 4.5,
                        "\(appearance): \(role.name) on \(surface.name) is \(rounded(ratio)):1, below the 4.5:1 body-text floor"
                    )
                }
            }
        }
    }

    func testHuesMeetLargeTextFloorOnPrimarySurfaces() {
        for traits in [light, dark] {
            let appearance = traits.userInterfaceStyle == .dark ? "dark" : "light"
            for hue in hues {
                for surface in surfaces where surface.name == "parchment" || surface.name == "paper" {
                    let ratio = contrastRatio(hue.color, surface.color, traits)
                    XCTAssertGreaterThanOrEqual(
                        ratio, 3.0,
                        "\(appearance): \(hue.name) on \(surface.name) is \(rounded(ratio)):1, below the 3:1 graphical floor"
                    )
                }
            }
        }
    }

    /// The ground ramp must actually step. Before Part C these sat within 0.1 of each other in
    /// lightness, which is why a card never separated from the background it sat on.
    func testSurfaceRampIsOrdered() {
        for traits in [light, dark] {
            let isDark = traits.userInterfaceStyle == .dark
            let values = surfaces.map { luminance($0.color, traits) }
            let deepest = values[0], ground = values[1], card = values[2], raised = values[3]

            if isDark {
                XCTAssertLessThan(deepest, ground, "dark: parchmentDeep must be darker than parchment")
                XCTAssertLessThan(ground, card, "dark: cards must sit above the ground")
                XCTAssertLessThan(card, raised, "dark: raised surfaces must sit above cards")
            } else {
                XCTAssertGreaterThan(deepest, 0.5, "light: the ramp should stay light")
                XCTAssertLessThan(deepest, ground, "light: parchmentDeep must be darker than parchment")
                XCTAssertGreaterThan(card, ground, "light: cards must sit above the ground")
            }
        }
    }

    /// Hues have to differ between appearances. A fixed hue cannot be accessible in both — the
    /// luminance window for 4.5:1 on near-black starts at 0.195 and the window for white ends at
    /// 0.161, so they do not overlap. If a hue ever stops adapting, this catches it.
    func testHuesAdaptBetweenAppearances() {
        for hue in hues {
            let lightLuminance = luminance(hue.color, light)
            let darkLuminance = luminance(hue.color, dark)
            XCTAssertGreaterThan(
                darkLuminance, lightLuminance,
                "\(hue.name) does not brighten for dark mode — it is likely a fixed colour again"
            )
        }
    }

    /// Guards the trap this suite was written against: a share card exported from a phone in
    /// light mode must carry the same colours as one exported from a phone in dark mode. That
    /// only holds while the renderer resolves `Raw` values directly — the moment anything routes
    /// a colour through `UIColor(Color)` first, pinning silently stops working and the recipient
    /// sees whichever appearance the sender happened to be using.
    func testExportColoursAreIndependentOfCurrentAppearance() {
        for mood in MoodType.allCases {
            let inLight = componentsOf(mood.tintRaw.resolvedColor(with: light)).red
            let inDark = componentsOf(mood.tintRaw.resolvedColor(with: dark)).red
            let pinned = componentsOf(mood.tintRaw.resolvedColor(with: MemoryInkColors.exportTraits)).red

            // Still dynamic. If a flattened colour ever reaches the renderer these would be equal,
            // and pinning below would become a no-op that quietly follows the ambient appearance.
            XCTAssertNotEqual(
                inLight, inDark, accuracy: 0.0001,
                "\(mood.rawValue): tintRaw is no longer dynamic, so pinning the export does nothing"
            )

            // And pinning selects the export appearance rather than whatever is current.
            XCTAssertEqual(
                pinned, inDark, accuracy: 0.0001,
                "\(mood.rawValue): pinned export colour is not the export appearance's value"
            )
        }

        // And the flattening itself, stated directly, so the reason is visible if it ever returns.
        let flattened = UIColor(MemoryInkColors.ink).resolvedColor(with: dark)
        let real = MemoryInkColors.Raw.ink.resolvedColor(with: dark)
        XCTAssertNotEqual(
            componentsOf(flattened).red, componentsOf(real).red, accuracy: 0.0001,
            "UIColor(Color) no longer flattens dynamic colours — if this fails, the Raw indirection may be simplifiable"
        )
    }

    // MARK: - Helpers

    private func componentsOf(_ color: UIColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    private func contrastRatio(_ a: UIColor, _ b: UIColor, _ traits: UITraitCollection) -> CGFloat {
        let la = luminance(a, traits), lb = luminance(b, traits)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private func luminance(_ color: UIColor, _ traits: UITraitCollection) -> CGFloat {
        let resolved = color.resolvedColor(with: traits)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * linearise(r) + 0.7152 * linearise(g) + 0.0722 * linearise(b)
    }

    private func linearise(_ channel: CGFloat) -> CGFloat {
        channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }

    private func rounded(_ value: CGFloat) -> String {
        String(format: "%.2f", value)
    }
}
