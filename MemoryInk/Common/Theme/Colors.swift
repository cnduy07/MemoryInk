import SwiftUI
import UIKit

enum MemoryInkColors {
    static let parchment = adaptive(light: uiColor(red: 0.956, green: 0.936, blue: 0.902), dark: uiColor(red: 0.120, green: 0.106, blue: 0.088))
    static let parchmentDeep = adaptive(light: uiColor(red: 0.888, green: 0.844, blue: 0.776), dark: uiColor(red: 0.082, green: 0.072, blue: 0.060))
    static let paper = adaptive(light: uiColor(red: 0.992, green: 0.976, blue: 0.948), dark: uiColor(red: 0.176, green: 0.154, blue: 0.126))
    static let paperWarm = adaptive(light: uiColor(red: 0.970, green: 0.942, blue: 0.900), dark: uiColor(red: 0.145, green: 0.126, blue: 0.102))
    static let ink = adaptive(light: uiColor(red: 0.135, green: 0.116, blue: 0.098), dark: uiColor(red: 0.918, green: 0.886, blue: 0.832))
    static let secondaryInk = adaptive(light: uiColor(red: 0.396, green: 0.350, blue: 0.294), dark: uiColor(red: 0.740, green: 0.682, blue: 0.594))
    static let tertiaryInk = adaptive(light: uiColor(red: 0.600, green: 0.540, blue: 0.468), dark: uiColor(red: 0.570, green: 0.520, blue: 0.454))
    static let hairline = adaptive(light: uiColor(red: 0.820, green: 0.774, blue: 0.694), dark: uiColor(red: 0.310, green: 0.276, blue: 0.222))
    static let filmShadow = adaptive(light: uiColor(red: 0.170, green: 0.128, blue: 0.088), dark: uiColor(red: 0.020, green: 0.018, blue: 0.014))
    static let vignette = adaptive(light: uiColor(red: 0.070, green: 0.060, blue: 0.048), dark: uiColor(red: 0.010, green: 0.010, blue: 0.008))

    static let sage = Color(red: 0.56, green: 0.63, blue: 0.52)
    static let amber = Color(red: 0.72, green: 0.55, blue: 0.34)
    static let sunlit = Color(red: 0.78, green: 0.61, blue: 0.36)
    static let rosewood = Color(red: 0.60, green: 0.38, blue: 0.35)
    static let mistBlue = Color(red: 0.48, green: 0.56, blue: 0.62)
    static let taupe = Color(red: 0.56, green: 0.50, blue: 0.44)

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }

    private static func uiColor(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}
