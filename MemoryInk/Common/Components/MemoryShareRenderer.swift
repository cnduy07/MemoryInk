import SwiftUI
import UIKit

/// A look for the exported share card. `classic` is the card MemoryInk has always produced;
/// the rest reuse the hand-tuned `BackgroundScene` gradients that until now only the slideshow
/// exporter could show.
struct MemoryShareTheme: Identifiable, Equatable {
    let id: String
    let name: String
    /// `nil` for `classic`, which is mood-tinted rather than scene-backed.
    let sceneId: String?
    /// Whether text sits on a dark ground and should be drawn light.
    let usesLightInk: Bool

    var scene: BackgroundScene? {
        guard let sceneId else { return nil }
        return BackgroundScene.all.first { $0.id == sceneId }
    }

    /// `usesLightInk: true` describes Classic's artwork rather than driving it — Classic has no
    /// scene, so it renders through the `drawBackground` path and never reads this flag. It is set
    /// truthfully anyway: since Part C its ground is the pinned `parchment`, which is near-black.
    /// If Classic is ever routed through the framed layout, the correct value is already here.
    static let classic = MemoryShareTheme(id: "classic", name: "Classic", sceneId: nil, usesLightInk: true)

    static let all: [MemoryShareTheme] = [
        classic,
        MemoryShareTheme(id: "golden_hour", name: "Golden Hour", sceneId: "golden_hour", usesLightInk: true),
        MemoryShareTheme(id: "night_ink", name: "Night Ink", sceneId: "night_ink", usesLightInk: true),
        MemoryShareTheme(id: "warm_parchment", name: "Parchment", sceneId: "warm_parchment", usesLightInk: false)
    ]

    static func theme(id: String) -> MemoryShareTheme {
        all.first { $0.id == id } ?? .classic
    }
}

struct MemoryShareRenderer {
    static func render(
        narrative: String,
        mood: MoodType,
        date: Date,
        photo: UIImage? = nil,
        theme: MemoryShareTheme = .classic
    ) -> UIImage {
        let size = CGSize(width: 1080, height: 1080)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)

            if let scene = theme.scene {
                drawFramed(
                    narrative: narrative,
                    mood: mood,
                    date: date,
                    photo: photo,
                    scene: scene,
                    usesLightInk: theme.usesLightInk,
                    in: rect
                )
            } else if let photo = photo {
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

    // MARK: - Themed "framed" layout

    /// Scene gradient behind a framed photo, rather than the classic full-bleed treatment —
    /// this is what makes a theme actually visible on a card that has a photo.
    private static func drawFramed(
        narrative: String,
        mood: MoodType,
        date: Date,
        photo: UIImage?,
        scene: BackgroundScene,
        usesLightInk: Bool,
        in rect: CGRect
    ) {
        scene.render(size: rect.size).draw(in: rect)

        let ink: UIColor = usesLightInk ? Self.inkOnDarkArtwork : Self.inkOnLightArtwork
        let margin: CGFloat = 92
        var cursorY: CGFloat = margin

        if let photo {
            let frame = CGRect(x: margin, y: margin, width: rect.width - margin * 2, height: 520)
            drawFramedPhoto(photo, in: frame)
            cursorY = frame.maxY + 56
        } else {
            cursorY = 260
        }

        cursorY = drawFramedBadge(mood: mood, at: CGPoint(x: margin, y: cursorY), ink: ink, usesLightInk: usesLightInk)
        cursorY += 26

        let narrativeHeight = rect.maxY - 180 - cursorY
        if narrativeHeight > 0 {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 8
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: photo == nil ? 42 : 36, weight: .medium),
                .foregroundColor: ink,
                .paragraphStyle: paragraph
            ]
            NSAttributedString(string: narrative, attributes: attributes).draw(
                with: CGRect(x: margin, y: cursorY, width: rect.width - margin * 2, height: narrativeHeight),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
        }

        let footnote: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .regular),
            .foregroundColor: ink.withAlphaComponent(0.72)
        ]
        date.formatted(date: .abbreviated, time: .omitted)
            .draw(at: CGPoint(x: margin, y: rect.maxY - 116), withAttributes: footnote)

        let watermark = "MemoryInk"
        let watermarkAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .medium),
            .foregroundColor: ink.withAlphaComponent(0.55)
        ]
        let watermarkSize = watermark.size(withAttributes: watermarkAttributes)
        watermark.draw(
            at: CGPoint(x: rect.maxX - watermarkSize.width - margin, y: rect.maxY - 114),
            withAttributes: watermarkAttributes
        )
    }

    private static func drawFramedPhoto(_ photo: UIImage, in frame: CGRect) {
        let path = UIBezierPath(roundedRect: frame, cornerRadius: 32)

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setShadow(offset: CGSize(width: 0, height: 14), blur: 34, color: UIColor.black.withAlphaComponent(0.28).cgColor)
        UIColor.black.withAlphaComponent(0.001).setFill()
        path.fill()
        context?.restoreGState()

        context?.saveGState()
        path.addClip()
        drawPhoto(photo, in: frame)
        context?.restoreGState()
    }

    /// Draws the mood pill and returns the y position just below it.
    private static func drawFramedBadge(mood: MoodType, at origin: CGPoint, ink: UIColor, usesLightInk: Bool) -> CGFloat {
        let text = mood.title.uppercased()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: ink.withAlphaComponent(0.92)
        ]
        let textSize = text.size(withAttributes: attributes)
        let badgeRect = CGRect(x: origin.x, y: origin.y, width: textSize.width + 42, height: 48)

        // The mood tint carries the badge on every theme. This used to fall back to flat white on
        // light-ink themes, which quietly dropped the one piece of colour the card was built around.
        let fill = exportColor(mood.tintRaw).withAlphaComponent(usesLightInk ? 0.34 : 0.26)
        fill.setFill()
        UIBezierPath(roundedRect: badgeRect, cornerRadius: 24).fill()
        text.draw(at: CGPoint(x: badgeRect.minX + 21, y: badgeRect.minY + 11), withAttributes: attributes)

        return badgeRect.maxY
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
            exportColor(mood.tintRaw).withAlphaComponent(0.18).cgColor,
            exportColor(MemoryInkColors.Raw.parchment).cgColor
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
            .foregroundColor: exportColor(MemoryInkColors.Raw.ink).withAlphaComponent(0.78)
        ]
        let textSize = badgeText.size(withAttributes: attributes)
        let badgeRect = CGRect(
            x: 92,
            y: 116,
            width: textSize.width + 42,
            height: 48
        )

        exportColor(mood.tintRaw).withAlphaComponent(0.22).setFill()
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
            .foregroundColor: exportColor(MemoryInkColors.Raw.ink),
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
            .foregroundColor: exportColor(MemoryInkColors.Raw.tertiaryInk)
        ]

        dateText.draw(at: CGPoint(x: 92, y: 842), withAttributes: attributes)
    }

    private static func drawWatermark(in rect: CGRect) {
        let watermark = "MemoryInk"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .medium),
            .foregroundColor: exportColor(MemoryInkColors.Raw.tertiaryInk)
        ]
        let size = watermark.size(withAttributes: attributes)
        watermark.draw(
            at: CGPoint(x: rect.maxX - size.width - 92, y: rect.maxY - 116),
            withAttributes: attributes
        )
    }

    /// Resolves an adaptive colour against a **pinned** appearance.
    ///
    /// Part C made every palette colour adapt to light/dark (it has to — no fixed colour can meet
    /// contrast against both a near-black and a white ground). Rendered output must not inherit
    /// that: a card exported from a phone in light mode would otherwise carry different colours
    /// than the same memory exported from a phone in dark mode, and the recipient sees whichever
    /// the sender happened to be in. Pinning makes a shared card look the same for everyone.
    /// Ink for artwork whose background is dark — the scene gradients and, since Part C, Classic.
    ///
    /// Deliberately *not* the palette's `ink`. A share card is a fixed picture: its background is
    /// either a hardcoded scene gradient or the pinned ground, neither of which follows the app's
    /// appearance. Reading ink from the palette meant the light `warm_parchment` scene asked for
    /// the palette's ink, which after pinning resolved to near-white — white text on pale
    /// parchment. Ink follows the artwork it sits on, nothing else.
    private static let inkOnDarkArtwork = UIColor.white

    /// Ink for artwork whose background is light (the `warm_parchment` scene).
    private static let inkOnLightArtwork = UIColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1)

    private static func exportColor(_ color: UIColor) -> UIColor {
        color.resolvedColor(with: MemoryInkColors.exportTraits)
    }

}
