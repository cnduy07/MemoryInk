import Foundation

final class VoiceService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        createVoiceDirectoryIfNeeded()
    }

    func voiceURL(for id: UUID, fileExtension: String = "m4a") -> URL {
        documentsURL
            .appendingPathComponent("voice", isDirectory: true)
            .appendingPathComponent("\(id.uuidString).\(fileExtension)")
    }

    func relativeVoicePath(for id: UUID, fileExtension: String = "m4a") -> String {
        "voice/\(id.uuidString).\(fileExtension)"
    }

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func createVoiceDirectoryIfNeeded() {
        let url = documentsURL.appendingPathComponent("voice", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
