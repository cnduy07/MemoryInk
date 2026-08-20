import SwiftUI
import UIKit

/// MemoryInk's colour system — **Cinematic Dark** (Part C, 2026-08-20).
///
/// The governing idea: *the photograph is the only bright object on screen.* Ground, chrome and
/// labels recede into near-black and low-contrast grey so colour enters the app almost entirely
/// through the user's own picture.
///
/// **Dark is designed, light is derived.** The dark values are the real design and the light ones
/// are their counterpart. Before Part C this ran the other way — light was designed and dark was a
/// dimmed copy of it — which is why dark mode used to read as "light mode with the lamp off".
///
/// **Everything adapts, including the hues.** That is not the obvious choice, so here is why it is
/// the only one available: for a colour to clear WCAG AA (4.5:1) against a near-black ground it
/// needs relative luminance ≥ 0.195, and to clear it against white it needs ≤ 0.161. Those windows
/// do not overlap, so *no single fixed colour can be accessible in both appearances* — it is
/// arithmetic, not taste. Dropping to the 3:1 graphical floor does admit fixed values, but only
/// muddy ones (amber lands on 0.59/0.46/0.27, a brown), which defeats the direction entirely.
/// So each hue carries a bright variant for black and a deeper one for white.
///
/// The cost of that choice is paid in `MemoryShareRenderer`, which bakes mood colour into exported
/// PNGs: it must resolve these against a **pinned** trait collection so a shared card looks the
/// same for everyone, rather than following whatever appearance the sender's phone was in.
///
/// Contrast floors held by every value below: text roles ≥ 4.5:1 on both `parchment` and `paper`
/// in both appearances; hues ≥ 4.2:1 on ground and ≥ 4.7:1 on card.
enum MemoryInkColors {

    // MARK: - Ground and surface
    //
    // A four-step ramp. Before Part C these sat between 0.89 and 0.99 lightness — barely a step
    // apart — which is the main reason cards never separated from the background.

    /// Deepest ground. Behind everything; also the vignette edge.
    static var parchmentDeep: Color { Color(Raw.parchmentDeep) }
    /// Standard app background.
    static var parchment: Color { Color(Raw.parchment) }
    /// Card and sheet surface — one clear step up from the ground.
    static var paper: Color { Color(Raw.paper) }
    /// Raised surface: controls on a card, selected rows, nested containers.
    static var paperWarm: Color { Color(Raw.paperWarm) }

    // MARK: - Text

    /// Primary text. 17.3:1 on `parchment` dark, 16.3:1 light.
    static var ink: Color { Color(Raw.ink) }
    /// Secondary text: subtitles, narrative metadata. 7.5:1 dark, 6.9:1 light.
    static var secondaryInk: Color { Color(Raw.secondaryInk) }
    /// Tertiary text: timestamps, captions, disabled states.
    ///
    /// Tuned against the *worst* surface it can land on — `paperWarm` in dark, `parchmentDeep` in
    /// light — not against the standard ground. Two earlier passes set it against the ground alone
    /// and both failed AA once checked across all four surfaces (4.23, then 4.25). Now ≥ 4.5 on
    /// every surface in both appearances, which is what the automated check in the Part C notes
    /// asserts.
    static var tertiaryInk: Color { Color(Raw.tertiaryInk) }

    // MARK: - Structure

    /// Hairline borders and dividers.
    static var hairline: Color { Color(Raw.hairline) }
    /// Card shadow. Pure black in dark — a tinted shadow against near-black only muddies the edge.
    static var filmShadow: Color { Color(Raw.filmShadow) }
    /// Vignette and scrim.
    static var vignette: Color { Color(Raw.vignette) }

    // MARK: - Semantic roles
    //
    // Prefer these over a hue name. A screen that wants "the accent" should say `accent`, not
    // `amber`. Naming by hue is what stopped the old palette holding together: the same colour
    // meant "mood: proud" on one screen and "vintage slideshow style" on another, so screens
    // picked by eye and nothing stayed consistent.

    /// The app's single accent. Anything meant to draw the eye uses this.
    static var accent: Color { amber }
    /// Accent at higher energy: active filter chips, selection, premium highlights.
    static var accentBright: Color { sunlit }
    /// Confirmation and positive state.
    static var success: Color { sage }
    /// Destructive and error state.
    static var destructive: Color { rosewood }
    /// "Nothing here" marks — empty calendar cells and similar.
    static var neutralMark: Color { taupe }

    /// Text and icons drawn **on top of** a hue fill — a filled button, a mood chip, a gradient
    /// pill. It must invert with the hue, not with the background.
    ///
    /// This is the one role that cannot be `.white`, which is what the whole app used before Part
    /// C. That worked while the hues were dark enough to carry white text. They are not any more:
    /// in dark mode a hue is *bright* (amber sits at 0.51 luminance), so white-on-amber falls to
    /// about 1.9:1 — failing, and painful to look at. Flipping to near-black there restores it to
    /// roughly 10:1, and light mode keeps near-white at about 4.7:1.
    static var onAccent: Color { Color(Raw.onAccent) }

    // MARK: - Hues
    //
    // Bright variants are tuned for the near-black ground; light variants are the same hue solved
    // down to the luminance that clears AA on white.

    /// The accent hue. Reach for `accent` instead.
    static var amber: Color { Color(Raw.amber) }
    static var sunlit: Color { Color(Raw.sunlit) }
    static var sage: Color { Color(Raw.sage) }
    static var rosewood: Color { Color(Raw.rosewood) }
    static var mistBlue: Color { Color(Raw.mistBlue) }
    static var taupe: Color { Color(Raw.taupe) }

    // MARK: - Mood hues
    //
    // One per `MoodType`, and the reason the hue tokens cannot simply be deleted: they are the
    // mood system, not decoration. Under Part C they shrink to badge-scale marks (C.3) instead of
    // tinting whole cards, so they are tuned to stay legible small.

    /// peaceful
    static var teal: Color { Color(Raw.teal) }
    /// nostalgic
    static var orchid: Color { Color(Raw.orchid) }
    /// happy
    static var gold: Color { Color(Raw.gold) }
    /// proud
    static var coral: Color { Color(Raw.coral) }
    /// sad
    static var ocean: Color { Color(Raw.ocean) }
    /// reflective
    static var twilight: Color { Color(Raw.twilight) }

    // MARK: - Construction

    /// The appearance exported imagery is rendered against, so a share card looks the same for
    /// everyone regardless of the sender's device appearance. See `MemoryShareRenderer`.
    static let exportTraits = UITraitCollection(userInterfaceStyle: .dark)

    // MARK: - UIKit source of truth
    //
    // Every token above is a `Color` *wrapper* over one of these. The dynamic `UIColor` has to be
    // the real definition, because `UIColor(someColor)` silently flattens a dynamic colour down to
    // whatever appearance happens to be current — after that round-trip `resolvedColor(with:)` is
    // a no-op and returns the same value for both traits. A contrast test caught this: all twelve
    // hues reported an identical luminance in light and dark, which is only possible if the
    // adaptation had already been thrown away.
    //
    // The practical consequence was in `MemoryShareRenderer`: pinning exports to a fixed
    // appearance appeared to work and did nothing. Anything that needs UIKit — rendering to an
    // image, a `CGColor`, an attributed string — must reach for `Raw` and resolve it explicitly.
    enum Raw {
        static let parchmentDeep = dynamic(light: rgb(0.910, 0.902, 0.886), dark: rgb(0.031, 0.031, 0.035))
        static let parchment = dynamic(light: rgb(0.961, 0.953, 0.941), dark: rgb(0.055, 0.054, 0.059))
        static let paper = dynamic(light: rgb(1.000, 1.000, 1.000), dark: rgb(0.098, 0.096, 0.102))
        static let paperWarm = dynamic(light: rgb(0.980, 0.973, 0.961), dark: rgb(0.133, 0.129, 0.137))
        static let onAccent = dynamic(light: rgb(1.000, 0.996, 0.988), dark: rgb(0.043, 0.041, 0.047))
        static let ink = dynamic(light: rgb(0.090, 0.086, 0.102), dark: rgb(0.957, 0.949, 0.937))
        static let secondaryInk = dynamic(light: rgb(0.333, 0.325, 0.310), dark: rgb(0.639, 0.631, 0.620))
        static let tertiaryInk = dynamic(light: rgb(0.395, 0.387, 0.372), dark: rgb(0.545, 0.537, 0.525))
        static let hairline = dynamic(light: rgb(0.855, 0.843, 0.827), dark: rgb(0.200, 0.198, 0.204))
        static let filmShadow = dynamic(light: rgb(0.100, 0.090, 0.080), dark: rgb(0.000, 0.000, 0.000))
        static let vignette = dynamic(light: rgb(0.070, 0.060, 0.048), dark: rgb(0.000, 0.000, 0.000))
        static let amber = dynamic(light: rgb(0.555, 0.433, 0.256), dark: rgb(0.910, 0.710, 0.420))
        static let sunlit = dynamic(light: rgb(0.541, 0.437, 0.276), dark: rgb(0.940, 0.760, 0.480))
        static let sage = dynamic(light: rgb(0.328, 0.491, 0.353), dark: rgb(0.520, 0.780, 0.560))
        static let rosewood = dynamic(light: rgb(0.692, 0.353, 0.353), dark: rgb(0.920, 0.470, 0.470))
        static let mistBlue = dynamic(light: rgb(0.372, 0.465, 0.544), dark: rgb(0.560, 0.700, 0.820))
        static let taupe = dynamic(light: rgb(0.472, 0.449, 0.434), dark: rgb(0.620, 0.590, 0.570))
        static let teal = dynamic(light: rgb(0.223, 0.499, 0.453), dark: rgb(0.340, 0.760, 0.690))
        static let orchid = dynamic(light: rgb(0.530, 0.399, 0.646), dark: rgb(0.730, 0.550, 0.890))
        static let gold = dynamic(light: rgb(0.543, 0.440, 0.206), dark: rgb(0.950, 0.770, 0.360))
        static let coral = dynamic(light: rgb(0.659, 0.374, 0.354), dark: rgb(0.950, 0.540, 0.510))
        static let ocean = dynamic(light: rgb(0.306, 0.466, 0.633), dark: rgb(0.440, 0.670, 0.910))
        static let twilight = dynamic(light: rgb(0.419, 0.434, 0.669), dark: rgb(0.570, 0.590, 0.910))

        private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        }

        private static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
            UIColor(red: red, green: green, blue: blue, alpha: 1)
        }
    }
}
