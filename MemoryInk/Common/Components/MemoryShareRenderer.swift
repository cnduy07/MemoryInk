import SwiftUI
import UIKit

struct MemoryShareRenderer {
    static func render(narrative: String, mood: MoodType, date: Date) -> UIImage {
        let size = CGSize(width: 1080, height: 1080)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)

            drawBackground(in: rect, mood: mood, context: cgContext)
            drawBadge(mood: mood, in: rect)
            drawNarrative(narrative, in: rect)
            drawDate(date, in: rect)
            drawWatermark(in: rect)
        }
    }

    private static func drawBackground(in rect: CGRect, mood: MoodType, context: CGContext) {
        let colors = [
            UIColor(mood.tint).withAlphaComponent(0.18).cgColor,
            UIColor(MemoryInkColors.parchment).cgColor
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])

        context.saveGState()
        context.drawLinearGradient(
            gradient!,
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            options: []
        )
        context.restoreGState()
    }

    private static func drawBadge(mood: MoodType, in rect: CGRect) {
        let badgeText = mood.title.uppercased()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: UIColor(MemoryInkColors.ink).withAlphaComponent(0.78)
        ]
        let textSize = badgeText.size(withAttributes: attributes)
        let badgeRect = CGRect(
            x: 92,
            y: 116,
            width: textSize.width + 42,
            height: 48
        )

        UIColor(mood.tint).withAlphaComponent(0.22).setFill()
        UIBezierPath(roundedRect: badgeRect, cornerRadius: 24).fill()
        badgeText.draw(
            at: CGPoint(x: badgeRect.minX + 21, y: badgeRect.minY + 11),
            withAttributes: attributes
        )
    }

    private static func drawNarrative(_ narrative: String, in rect: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8
        paragraph.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 42, weight: .medium),
            .foregroundColor: UIColor(MemoryInkColors.ink),
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: narrative, attributes: attributes)
        attributed.draw(
            with: CGRect(x: 92, y: 254, width: rect.width - 184, height: 540),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }

    private static func drawDate(_ date: Date, in rect: CGRect) {
        let dateText = date.formatted(date: .abbreviated, time: .omitted)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .regular),
            .foregroundColor: UIColor(MemoryInkColors.tertiaryInk)
        ]

        dateText.draw(at: CGPoint(x: 92, y: 842), withAttributes: attributes)
    }

    private static func drawWatermark(in rect: CGRect) {
        let watermark = "MemoryInk"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .medium),
            .foregroundColor: UIColor(MemoryInkColors.tertiaryInk)
        ]
        let size = watermark.size(withAttributes: attributes)
        watermark.draw(
            at: CGPoint(x: rect.maxX - size.width - 92, y: rect.maxY - 116),
            withAttributes: attributes
        )
    }
}
