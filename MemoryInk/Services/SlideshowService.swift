import AVFoundation
import SwiftUI
import UIKit

@MainActor
final class SlideshowService: ObservableObject {
    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var progress: Double = 0

    enum SlideshowError: LocalizedError {
        case tooFewEntries
        case exportFailed(String)

        var errorDescription: String? {
            switch self {
            case .tooFewEntries:
                return "Select at least 2 memories."
            case .exportFailed:
                return "Couldn't create the slideshow right now. Try again."
            }
        }
    }

    private enum Constants {
        static let width = 1080
        static let height = 1920
        static let fps: Int32 = 30
        static let framesPerEntry = 75
        static let canvasSize = CGSize(width: width, height: height)
    }

    private nonisolated var videoSettings: [String: Any] {
        [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Constants.width,
            AVVideoHeightKey: Constants.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 4_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
    }

    private nonisolated var pixelBufferAttrs: [String: Any] {
        [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Constants.width,
            kCVPixelBufferHeightKey as String: Constants.height
        ]
    }

    func generate(entries: [JournalEntry], isPremium: Bool) async throws -> URL {
        guard entries.count >= 2 else { throw SlideshowError.tooFewEntries }

        isGenerating = true
        progress = 0
        defer {
            isGenerating = false
            progress = 0
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("memoryink_slideshow_\(UUID().uuidString).mp4")

        try await Task.detached(priority: .userInitiated) { [weak self, entries, isPremium] in
            guard let self else { return }

            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.videoSettings)
            writerInput.expectsMediaDataInRealTime = false

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: writerInput,
                sourcePixelBufferAttributes: self.pixelBufferAttrs
            )

            guard assetWriter.canAdd(writerInput) else {
                throw SlideshowError.exportFailed("writer input unavailable")
            }

            assetWriter.add(writerInput)
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)

            let frameDuration = CMTime(value: 1, timescale: Constants.fps)
            var currentTime = CMTime.zero
            let totalFrames = entries.count * Constants.framesPerEntry

            for (entryIndex, entry) in entries.enumerated() {
                for frameIndex in 0..<Constants.framesPerEntry {
                    while !writerInput.isReadyForMoreMediaData {
                        try await Task.sleep(nanoseconds: 1_000_000)
                    }

                    let pixelBuffer = try self.renderFrame(
                        entry: entry,
                        frameIndex: frameIndex,
                        isPremium: isPremium,
                        adaptor: adaptor
                    )

                    guard adaptor.append(pixelBuffer, withPresentationTime: currentTime) else {
                        throw SlideshowError.exportFailed(assetWriter.error?.localizedDescription ?? "append failed")
                    }

                    currentTime = CMTimeAdd(currentTime, frameDuration)

                    let globalFrame = entryIndex * Constants.framesPerEntry + frameIndex
                    let newProgress = Double(globalFrame + 1) / Double(totalFrames)
                    await MainActor.run { self.progress = newProgress }
                }
            }

            writerInput.markAsFinished()
            await assetWriter.finishWriting()

            if assetWriter.status == .failed {
                throw SlideshowError.exportFailed(assetWriter.error?.localizedDescription ?? "unknown")
            }
        }.value

        return outputURL
    }

    func generateFromImages(
        _ images: [UIImage],
        mood: MoodType,
        style: SlideshowStyle = .natural,
        isPremium: Bool,
        totalSeconds: Int = 10
    ) async throws -> URL {
        guard images.count >= 2 else { throw SlideshowError.tooFewEntries }

        isGenerating = true
        progress = 0
        defer { isGenerating = false; progress = 0 }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("memoryink_creation_\(UUID().uuidString).mp4")

        let framesPerImage = max(15, (totalSeconds * Int(Constants.fps)) / images.count)
        let totalFrames = images.count * framesPerImage

        try await Task.detached(priority: .userInitiated) { [weak self, images, mood, style, isPremium, framesPerImage, totalFrames] in
            guard let self else { return }

            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.videoSettings)
            writerInput.expectsMediaDataInRealTime = false

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: writerInput,
                sourcePixelBufferAttributes: self.pixelBufferAttrs
            )

            guard assetWriter.canAdd(writerInput) else {
                throw SlideshowError.exportFailed("writer input unavailable")
            }

            assetWriter.add(writerInput)
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)

            let frameDuration = CMTime(value: 1, timescale: Constants.fps)
            var currentTime = CMTime.zero

            for (imgIndex, image) in images.enumerated() {
                for frameIndex in 0..<framesPerImage {
                    while !writerInput.isReadyForMoreMediaData {
                        try await Task.sleep(nanoseconds: 1_000_000)
                    }

                    let pixelBuffer = try self.renderImageFrame(
                        image: image,
                        frameIndex: frameIndex,
                        framesPerImage: framesPerImage,
                        isPremium: isPremium,
                        mood: mood,
                        style: style,
                        adaptor: adaptor
                    )

                    guard adaptor.append(pixelBuffer, withPresentationTime: currentTime) else {
                        throw SlideshowError.exportFailed("append failed")
                    }

                    currentTime = CMTimeAdd(currentTime, frameDuration)
                    let globalFrame = imgIndex * framesPerImage + frameIndex
                    let p = Double(globalFrame + 1) / Double(totalFrames)
                    await MainActor.run { self.progress = p }
                }
            }

            writerInput.markAsFinished()
            await assetWriter.finishWriting()

            if assetWriter.status == .failed {
                throw SlideshowError.exportFailed(assetWriter.error?.localizedDescription ?? "unknown")
            }
        }.value

        let finalURL = (try? await mixAudio(videoURL: outputURL, mood: mood)) ?? outputURL
        return finalURL
    }

    private func mixAudio(videoURL: URL, mood: MoodType) async throws -> URL {
        let candidates = mood.audioFileNames
        guard let chosenName = candidates.randomElement(),
              let audioURL = Bundle.main.url(forResource: chosenName, withExtension: "mp3") else {
            return videoURL
        }

        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)

        let videoDuration = try await videoAsset.load(.duration)
        let audioDuration = try await audioAsset.load(.duration)

        let videoTracks = try await videoAsset.loadTracks(withMediaType: .video)
        let audioTracks = try await audioAsset.loadTracks(withMediaType: .audio)

        guard let videoTrack = videoTracks.first else { return videoURL }

        let composition = AVMutableComposition()

        guard let compVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { return videoURL }

        try compVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: videoDuration),
            of: videoTrack,
            at: .zero
        )

        if let audioTrack = audioTracks.first,
           let compAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            var insertTime = CMTime.zero
            while insertTime < videoDuration {
                let remaining = CMTimeSubtract(videoDuration, insertTime)
                let segmentDuration = CMTimeMinimum(audioDuration, remaining)
                try compAudioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: segmentDuration),
                    of: audioTrack,
                    at: insertTime
                )
                insertTime = CMTimeAdd(insertTime, segmentDuration)
            }
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("memoryink_audio_\(UUID().uuidString).mp4")

        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            return videoURL
        }

        session.outputURL = outputURL
        session.outputFileType = .mp4

        await session.export()

        if session.status == .completed {
            try? FileManager.default.removeItem(at: videoURL)
            return outputURL
        } else {
            return videoURL
        }
    }

    private nonisolated func renderFrame(
        entry: JournalEntry,
        frameIndex: Int,
        isPremium: Bool,
        adaptor: AVAssetWriterInputPixelBufferAdaptor
    ) throws -> CVPixelBuffer {
        guard let pixelBufferPool = adaptor.pixelBufferPool else {
            throw SlideshowError.exportFailed("pixel buffer pool unavailable")
        }

        var optionalPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &optionalPixelBuffer)

        guard status == kCVReturnSuccess, let pixelBuffer = optionalPixelBuffer else {
            throw SlideshowError.exportFailed("pixel buffer unavailable")
        }

        let canvasRect = CGRect(origin: .zero, size: Constants.canvasSize)
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1.0
        rendererFormat.opaque = true
        let uiRenderer = UIGraphicsImageRenderer(size: Constants.canvasSize, format: rendererFormat)

        let frameImage = uiRenderer.image { ctx in
            UIColor.black.setFill()
            UIRectFill(canvasRect)

            if let image = ImagePipelineService.image(forRelativePath: entry.thumbnailPath) {
                let drawRect = imageDrawRect(frameIndex: frameIndex, isPremium: isPremium)
                drawImage(image, filling: drawRect)
            } else {
                drawMoodGradient(for: entry, in: ctx.cgContext, rect: canvasRect)
            }

            drawBottomScrim(in: ctx.cgContext)
            drawMoodBadge(for: entry)
            drawDate(for: entry)
            drawWatermark()
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
              let cgImage = frameImage.cgImage,
              let context = CGContext(
                data: baseAddress,
                width: Constants.width,
                height: Constants.height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
              ) else {
            throw SlideshowError.exportFailed("render context unavailable")
        }

        context.draw(cgImage, in: canvasRect)
        return pixelBuffer
    }

    private nonisolated func renderImageFrame(
        image: UIImage,
        frameIndex: Int,
        framesPerImage: Int,
        isPremium: Bool,
        mood: MoodType,
        style: SlideshowStyle,
        adaptor: AVAssetWriterInputPixelBufferAdaptor
    ) throws -> CVPixelBuffer {
        guard let pool = adaptor.pixelBufferPool else {
            throw SlideshowError.exportFailed("pixel buffer pool unavailable")
        }

        var optionalPixelBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &optionalPixelBuffer) == kCVReturnSuccess,
              let pixelBuffer = optionalPixelBuffer else {
            throw SlideshowError.exportFailed("pixel buffer unavailable")
        }

        let canvas = Constants.canvasSize
        let canvasRect = CGRect(origin: .zero, size: canvas)
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1.0
        rendererFormat.opaque = true
        let uiRenderer = UIGraphicsImageRenderer(size: canvas, format: rendererFormat)

        let frameImage = uiRenderer.image { ctx in
            switch style {
            case .minimalist:
                UIColor.white.setFill()
            default:
                UIColor.black.setFill()
            }
            UIRectFill(canvasRect)

            let photoRect: CGRect
            switch style {
            case .minimalist:
                let inset = canvas.width * 0.075
                photoRect = canvasRect.insetBy(dx: inset, dy: canvas.height * 0.12)
            default:
                photoRect = kenBurnsRect(frameIndex: frameIndex, framesPerImage: framesPerImage, isPremium: isPremium)
            }
            drawImage(image, filling: photoRect)

            switch style {
            case .cinematic:
                let barH = canvas.height * 0.10
                UIColor.black.setFill()
                UIRectFill(CGRect(x: 0, y: 0, width: canvas.width, height: barH))
                UIRectFill(CGRect(x: 0, y: canvas.height - barH, width: canvas.width, height: barH))
                UIColor(red: 0.90, green: 0.68, blue: 0.20, alpha: 0.13).setFill()
                UIBezierPath(rect: canvasRect).fill()
            case .vintage:
                UIColor(red: 0.45, green: 0.28, blue: 0.08, alpha: 0.32).setFill()
                UIBezierPath(rect: canvasRect).fill()
                drawFilmGrain(in: canvasRect)
                drawVignette(in: canvasRect)
            case .minimalist, .natural:
                break
            }

            if style != .minimalist {
                drawBottomScrim(in: ctx.cgContext)
            }

            let badgeY: CGFloat = style == .cinematic ? canvas.height * 0.84 : canvas.height * 0.89
            let badgeRect = CGRect(x: 56, y: badgeY, width: 200, height: 44)
            let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: 22)
            let badgeColor: UIColor = style == .minimalist
                ? UIColor(mood.tint).withAlphaComponent(0.22)
                : UIColor(mood.tint).withAlphaComponent(0.30)
            badgeColor.setFill()
            badgePath.fill()
            let badgeTextColor: UIColor = style == .minimalist ? UIColor(mood.tint) : .white
            let badgeAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                .foregroundColor: badgeTextColor
            ]
            let badgeText = mood.title.uppercased() as NSString
            let badgeSize = badgeText.size(withAttributes: badgeAttrs)
            badgeText.draw(
                in: CGRect(
                    x: badgeRect.midX - badgeSize.width / 2,
                    y: badgeRect.midY - badgeSize.height / 2,
                    width: badgeSize.width,
                    height: badgeSize.height
                ),
                withAttributes: badgeAttrs
            )

            let watermarkColor: UIColor = style == .minimalist
                ? UIColor.darkGray.withAlphaComponent(0.40)
                : UIColor.white.withAlphaComponent(0.35)
            let watermarkAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                .foregroundColor: watermarkColor
            ]
            let watermarkText = "MemoryInk" as NSString
            let watermarkSize = watermarkText.size(withAttributes: watermarkAttrs)
            watermarkText.draw(
                at: CGPoint(x: CGFloat(Constants.width) - 56 - watermarkSize.width, y: badgeY + 52),
                withAttributes: watermarkAttrs
            )
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
              let cgImage = frameImage.cgImage,
              let context = CGContext(
                data: baseAddress,
                width: Constants.width,
                height: Constants.height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
              ) else {
            throw SlideshowError.exportFailed("render context unavailable")
        }

        context.draw(cgImage, in: canvasRect)
        return pixelBuffer
    }

    private nonisolated func drawFilmGrain(in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        UIColor.white.withAlphaComponent(0.055).setFill()
        let dotSize: CGFloat = 1.5
        let spacing: CGFloat = 9
        var x = rect.minX
        while x < rect.maxX {
            var y = rect.minY
            while y < rect.maxY {
                if (Int(x * 5 + y * 11)) % 3 == 0 {
                    let dot = CGRect(x: x + CGFloat(Int(y) % 3) - 1, y: y, width: dotSize, height: dotSize)
                    ctx.fillEllipse(in: dot)
                }
                y += spacing
            }
            x += spacing
        }
    }

    private nonisolated func drawVignette(in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let colors = [UIColor.black.withAlphaComponent(0.52).cgColor, UIColor.clear.cgColor] as CFArray
        let radius = min(rect.width, rect.height) * 0.72
        let corners: [CGPoint] = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        for corner in corners {
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            ) else { continue }
            ctx.drawRadialGradient(
                gradient,
                startCenter: corner, startRadius: 0,
                endCenter: corner, endRadius: radius,
                options: []
            )
        }
    }

    private nonisolated func kenBurnsRect(frameIndex: Int, framesPerImage: Int, isPremium: Bool) -> CGRect {
        guard isPremium, framesPerImage > 1 else {
            return CGRect(origin: .zero, size: Constants.canvasSize)
        }

        let t = Double(frameIndex) / Double(framesPerImage - 1)
        let scale = 1.0 + 0.08 * t
        let drawW = Double(Constants.width) / scale
        let drawH = Double(Constants.height) / scale
        return CGRect(
            x: (Double(Constants.width) - drawW) / 2,
            y: (Double(Constants.height) - drawH) / 2,
            width: drawW,
            height: drawH
        )
    }

    private nonisolated func imageDrawRect(frameIndex: Int, isPremium: Bool) -> CGRect {
        guard isPremium else {
            return CGRect(origin: .zero, size: Constants.canvasSize)
        }

        let t = Double(frameIndex) / Double(Constants.framesPerEntry - 1)
        let scale = 1.0 + 0.08 * t
        let drawW = Double(Constants.width) / scale
        let drawH = Double(Constants.height) / scale

        return CGRect(
            x: (Double(Constants.width) - drawW) / 2,
            y: (Double(Constants.height) - drawH) / 2,
            width: drawW,
            height: drawH
        )
    }

    private nonisolated func drawImage(_ image: UIImage, filling rect: CGRect) {
        guard image.size.width > 0, image.size.height > 0 else { return }

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        defer { context.restoreGState() }

        let imageAspect = image.size.width / image.size.height
        let rectAspect = rect.width / rect.height
        var drawRect = rect

        if imageAspect > rectAspect {
            let width = rect.height * imageAspect
            drawRect = CGRect(
                x: rect.midX - width / 2,
                y: rect.minY,
                width: width,
                height: rect.height
            )
        } else {
            let height = rect.width / imageAspect
            drawRect = CGRect(
                x: rect.minX,
                y: rect.midY - height / 2,
                width: rect.width,
                height: height
            )
        }

        UIRectClip(rect)
        image.draw(in: drawRect)
    }

    private nonisolated func drawMoodGradient(for entry: JournalEntry, in context: CGContext, rect: CGRect) {
        let tint = UIColor(entry.mood.tint)
        let colors = [
            tint.withAlphaComponent(0.86).cgColor,
            tint.withAlphaComponent(0.44).cgColor
        ] as CFArray

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0, 1]
        ) else { return }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            options: []
        )
    }

    private nonisolated func drawBottomScrim(in context: CGContext) {
        let colors = [
            CGColor(gray: 0, alpha: 0),
            CGColor(gray: 0, alpha: 0.75)
        ] as CFArray

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: colors,
            locations: [0, 1]
        ) else { return }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: Constants.width / 2, y: 1050),
            end: CGPoint(x: Constants.width / 2, y: Constants.height),
            options: []
        )
    }

    private nonisolated func drawMoodBadge(for entry: JournalEntry) {
        let badgeRect = CGRect(x: 56, y: 1720, width: 200, height: 44)
        let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: 22)
        UIColor(entry.mood.tint).withAlphaComponent(0.28).setFill()
        badgePath.fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let text = entry.mood.title.uppercased() as NSString
        let size = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: badgeRect.midX - size.width / 2,
            y: badgeRect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        text.draw(in: textRect, withAttributes: attributes)
    }

    private nonisolated func drawDate(for entry: JournalEntry) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.60)
        ]
        let text = entry.createdAt.formatted(date: .abbreviated, time: .omitted) as NSString
        text.draw(at: CGPoint(x: 56, y: 1774), withAttributes: attributes)
    }

    private nonisolated func drawWatermark() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.35)
        ]
        let text = "MemoryInk" as NSString
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(x: CGFloat(Constants.width) - 56 - size.width, y: 1774),
            withAttributes: attributes
        )
    }
}
