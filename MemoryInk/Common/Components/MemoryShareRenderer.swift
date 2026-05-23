import SwiftUI
import UIKit

struct MemoryShareRenderer {
    static func render(narrative: String, mood: MoodType, date: Date, photo: UIImage? = nil) -> UIImage {
        let size = CGSize(width: 1080, height: 1080)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)

            if let photo = photo {
                drawPhoto(photo, in: rect)
                drawPhotoOverlay(in: rect, context: cgContext)
                drawBadgeWhite(mood: mood, in: rect)
                drawNarrativeWhite(narrative, in: rect)
                drawDateWhite(date, in: rect)
                drawWatermarkWhite(in: rect)
            } else {
                drawBackground(in: rect, mood: mood, context: cgContext)
                drawBadge(mood: mood, in: rect)
                drawNarrative(narrative, in: rect)
                drawDate(date, in: rect)
                drawWatermark(in: rect)
            }
        }
    }

    private static func drawPhoto(_ photo: UIImage, in rect: CGRect) {
        let photoSize = photo.size
        guard photoSize.width > 0, photoSize.height > 0 else { return }
        let scale = max(rect.width / photoSize.width, rect.height / photoSize.height)
        let scaledWidth = photoSize.width * scale
        let scaledHeight = photoSize.height * scale
        let drawRect = CGRect(
            x: (rect.width - scaledWidth) / 2,
            y: (rect.height - scaledHeight) / 2,
            width: scaledWidth,
            height: scaledHeight
        )
        photo.draw(in: drawRect)
    }

    private static func drawPhotoOverlay(in rect: CGRect, context: CGContext) {
        let colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.72).cgColor
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.25, 1.0]) else { return }
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
    }

    private static func drawBadgeWhite(mood: MoodType, in rect: CGRect) {
        let badgeText = mood.title.uppercased()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.90)
        ]
        let textSize = badgeText.size(withAttributes: attributes)
        let badgeRect = CGRect(x: 92, y: 116, width: textSize.width + 42, height: 48)
        UIColor.white.withAlphaComponent(0.18).setFill()
        UIBezierPath(roundedRect: badgeRect, cornerRadius: 24).fill()
        badgeText.draw(at: CGPoint(x: badgeRect.minX + 21, y: badgeRect.minY + 11), withAttributes: attributes)
    }

    private static func drawNarrativeWhite(_ narrative: String, in rect: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8
        paragraph.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 42, weight: .medium),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: narrative, attributes: attributes)
        attributed.draw(
            with: CGRect(x: 92, y: 560, width: rect.width - 184, height: 380),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }

    private static func drawDateWhite(_ date: Date, in rect: CGRect) {
        let dateText = date.formatted(date: .abbreviated, time: .omitted)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.72)
        ]
        dateText.draw(at: CGPoint(x: 92, y: 940), withAttributes: attributes)
    }

    private static func drawWatermarkWhite(in rect: CGRect) {
        let watermark = "MemoryInk"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ]
        let size = watermark.size(withAttributes: attributes)
        watermark.draw(at: CGPoint(x: rect.maxX - size.width - 92, y: rect.maxY - 116), withAttributes: attributes)
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
