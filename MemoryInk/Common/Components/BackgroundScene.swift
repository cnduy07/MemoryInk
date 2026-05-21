import SwiftUI
import UIKit

struct BackgroundScene: Identifiable {
    let id: String
    let name: String
    let colors: [UIColor]
    let startPoint: CGPoint
    let endPoint: CGPoint

    static let all: [BackgroundScene] = [
        BackgroundScene(
            id: "golden_hour",
            name: "Golden Hour",
            colors: [UIColor(red: 0.98, green: 0.80, blue: 0.42, alpha: 1),
                     UIColor(red: 0.95, green: 0.55, blue: 0.30, alpha: 1),
                     UIColor(red: 0.72, green: 0.35, blue: 0.32, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "misty_morning",
            name: "Misty Morning",
            colors: [UIColor(red: 0.75, green: 0.85, blue: 0.95, alpha: 1),
                     UIColor(red: 0.60, green: 0.78, blue: 0.85, alpha: 1),
                     UIColor(red: 0.88, green: 0.92, blue: 0.90, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "sage_garden",
            name: "Sage Garden",
            colors: [UIColor(red: 0.55, green: 0.72, blue: 0.60, alpha: 1),
                     UIColor(red: 0.70, green: 0.82, blue: 0.68, alpha: 1),
                     UIColor(red: 0.88, green: 0.92, blue: 0.84, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "rose_dusk",
            name: "Rose Dusk",
            colors: [UIColor(red: 0.72, green: 0.42, blue: 0.50, alpha: 1),
                     UIColor(red: 0.88, green: 0.60, blue: 0.55, alpha: 1),
                     UIColor(red: 0.96, green: 0.82, blue: 0.72, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "night_ink",
            name: "Night Ink",
            colors: [UIColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 1),
                     UIColor(red: 0.14, green: 0.18, blue: 0.32, alpha: 1),
                     UIColor(red: 0.22, green: 0.28, blue: 0.42, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "ocean_calm",
            name: "Ocean Calm",
            colors: [UIColor(red: 0.22, green: 0.55, blue: 0.75, alpha: 1),
                     UIColor(red: 0.40, green: 0.72, blue: 0.85, alpha: 1),
                     UIColor(red: 0.75, green: 0.90, blue: 0.92, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "forest_deep",
            name: "Forest Deep",
            colors: [UIColor(red: 0.10, green: 0.28, blue: 0.18, alpha: 1),
                     UIColor(red: 0.22, green: 0.45, blue: 0.30, alpha: 1),
                     UIColor(red: 0.48, green: 0.65, blue: 0.45, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        ),
        BackgroundScene(
            id: "warm_parchment",
            name: "Parchment",
            colors: [UIColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1),
                     UIColor(red: 0.88, green: 0.82, blue: 0.70, alpha: 1),
                     UIColor(red: 0.80, green: 0.74, blue: 0.62, alpha: 1)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
    ]

    /// Renders this scene as a UIImage at the given size.
    func render(size: CGSize = CGSize(width: 800, height: 1000)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgContext = ctx.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgColors = colors.map(\.cgColor) as CFArray
            let locations: [CGFloat] = colors.enumerated().map { i, _ in
                CGFloat(i) / CGFloat(max(colors.count - 1, 1))
            }
            guard let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: cgColors,
                locations: locations
            ) else { return }

            let start = CGPoint(x: startPoint.x * size.width, y: startPoint.y * size.height)
            let end = CGPoint(x: endPoint.x * size.width, y: endPoint.y * size.height)
            cgContext.drawLinearGradient(
                gradient,
                start: start,
                end: end,
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
    }

    /// Returns a SwiftUI Color for previewing (uses the middle color).
    var previewColors: [Color] {
        colors.map { Color(uiColor: $0) }
    }
}
