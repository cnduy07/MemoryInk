import SwiftUI

enum MemoryInkMotion {
    static func quick(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.20)
    }

    static func standard(reduceMotion: Bool, delay: Double = 0) -> Animation {
        let animation = reduceMotion
            ? Animation.linear(duration: 0.01)
            : Animation.easeInOut(duration: 0.26)
        return delay > 0 && !reduceMotion ? animation.delay(delay) : animation
    }
}

struct MemoryInkAmbientBackdrop: View {
    let mood: MoodType?
    var intensity: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isSettled = false

    private var primaryAccent: Color {
        mood?.tint ?? MemoryInkColors.orchid
    }

    private var secondaryAccent: Color {
        mood?.secondaryTint ?? MemoryInkColors.ocean
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let height = max(proxy.size.height, 1)
            let colorStrength = reduceTransparency ? 0.12 : 0.28 * intensity

            ZStack {
                LinearGradient(
                    colors: [
                        MemoryInkColors.parchment,
                        MemoryInkColors.paperWarm,
                        MemoryInkColors.parchmentDeep
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        primaryAccent.opacity(colorStrength),
                        primaryAccent.opacity(0)
                    ],
                    center: .center,
                    startRadius: 8,
                    endRadius: width * 0.62
                )
                .frame(width: width * 1.2, height: width * 1.2)
                .offset(
                    x: isSettled ? -width * 0.22 : width * 0.03,
                    y: isSettled ? -height * 0.23 : -height * 0.12
                )

                RadialGradient(
                    colors: [
                        secondaryAccent.opacity(colorStrength * 0.88),
                        secondaryAccent.opacity(0)
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: width * 0.58
                )
                .frame(width: width * 1.08, height: width * 1.08)
                .offset(
                    x: isSettled ? width * 0.30 : width * 0.12,
                    y: isSettled ? height * 0.27 : height * 0.18
                )

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.14),
                        Color.clear,
                        MemoryInkColors.vignette.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .animation(
                MemoryInkMotion.standard(reduceMotion: reduceMotion),
                value: mood
            )
            .onAppear {
                withAnimation(
                    reduceMotion
                        ? .linear(duration: 0.01)
                        : .easeOut(duration: 1.15)
                ) {
                    isSettled = true
                }
            }
        }
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
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.988)
            .offset(y: isVisible || reduceMotion ? 0 : 12)
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
