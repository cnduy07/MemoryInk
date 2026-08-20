import SwiftUI

/// Motion for the Cinematic Dark direction (C.6): things resolve out of and back into the dark
/// rather than springing. Fade carries the change and a small defocus carries the depth; scale is
/// reserved for direct manipulation, where the finger is the thing moving.
enum MemoryInkMotion {
    /// Immediate feedback — a press, a toggle. Short enough to feel attached to the finger.
    static func quick(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.20)
    }

    /// The app's default. Slightly longer than the old 0.26s: a fade needs more time to read as
    /// deliberate than a scale does, because there is no movement to track.
    static func standard(reduceMotion: Bool, delay: Double = 0) -> Animation {
        let animation = reduceMotion
            ? Animation.linear(duration: 0.01)
            : Animation.easeInOut(duration: 0.32)
        return delay > 0 && !reduceMotion ? animation.delay(delay) : animation
    }

    /// For content arriving over something else — a detail opening, a sheet resolving.
    static func cinematic(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.42)
    }

    /// The house transition: fade plus a short defocus, no scale.
    ///
    /// `.blur` on the way in is what replaces the scale — it reads as the subject coming into
    /// focus rather than growing, which is the difference between "cinematic" and "an alert box".
    static func resolve(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .opacity.combined(with: .modifier(
            active: DefocusModifier(radius: 8),
            identity: DefocusModifier(radius: 0)
        ))
    }
}

/// Blur as a transition step. Kept separate so `reduceMotion` can drop it entirely rather than
/// animating a blur radius at 0.01s, which reads as a flicker.
struct DefocusModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

/// The ground the whole app sits on (C.4).
///
/// This used to paint two drifting mood-coloured radial gradients over a three-stop parchment
/// gradient, animating for 1.15s on every appearance. On a near-black ground that reads as a
/// coloured haze behind the photographs — precisely the competition Cinematic Dark exists to
/// remove. What is left is the ground itself and a single faint luminance falloff, so the eye has
/// somewhere to rest without anything asking for attention.
///
/// `mood` and `intensity` are kept in the signature: every screen passes them, and a future
/// direction may want them back. They are deliberately unused rather than removed, so that the
/// call sites do not all have to churn for a decision that might reverse.
struct MemoryInkAmbientBackdrop: View {
    let mood: MoodType?
    var intensity: Double = 1

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            MemoryInkColors.parchment

            if !reduceTransparency {
                LinearGradient(
                    colors: [
                        MemoryInkColors.paperWarm.opacity(0.5),
                        MemoryInkColors.parchment,
                        MemoryInkColors.parchmentDeep
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MemoryInkEntranceModifier: ViewModifier {
    let delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .blur(radius: isVisible || reduceMotion ? 0 : 6)
            .onAppear {
                withAnimation(
                    MemoryInkMotion.standard(
                        reduceMotion: reduceMotion,
                        delay: delay
                    )
                ) {
                    isVisible = true
                }
            }
    }
}

struct MemoryInkPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                reduceMotion || !configuration.isPressed ? 1 : 0.972
            )
            .brightness(configuration.isPressed ? 0.025 : 0)
            .animation(
                MemoryInkMotion.quick(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }
}

extension View {
    func memoryInkEntrance(delay: Double = 0) -> some View {
        modifier(MemoryInkEntranceModifier(delay: delay))
    }
}
