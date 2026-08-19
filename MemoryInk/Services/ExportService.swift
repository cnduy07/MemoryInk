import Foundation

/// Writes a local, metadata-only backup of the journal that the user can save anywhere
/// through the share sheet (Files, Mail, anywhere iOS offers).
///
/// **Photos are never included.** The export carries a photo's *file name* so a future import
/// could match it back up on this device — never image bytes, never EXIF, never location. The
/// whole thing is built on-device; nothing is uploaded, and this is free for every user.
struct ExportService {
    static let formatVersion = 1

    enum ExportError: LocalizedError {
        case nothingToExport

        var errorDescription: String? {
            switch self {
            case .nothingToExport:
                return "There's nothing to export yet."
            }
        }
    }

    /// Builds the backup file and returns its location in the temporary directory.
    static func exportMetadata(entries: [JournalEntry], now: Date = Date()) throws -> URL {
        guard !entries.isEmpty else { throw ExportError.nothingToExport }

        let document = Document(
            formatVersion: formatVersion,
            exportedAt: now,
            entryCount: entries.count,
            note: "Your photos are not included — they stay on this device.",
            entries: entries
                .sorted { $0.createdAt < $1.createdAt }
                .map(Entry.init(entry:))
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(for: now))
        try encoder.encode(document).write(to: url, options: .atomic)
        return url
    }

    static func fileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "MemoryInk-Backup-\(formatter.string(from: date)).json"
    }

    // MARK: - Document shape

    private struct Document: Encodable {
        let app = "MemoryInk"
        let formatVersion: Int
        let exportedAt: Date
        let entryCount: Int
        let note: String
        let entries: [Entry]

        enum CodingKeys: String, CodingKey {
            case app
            case formatVersion = "format_version"
            case exportedAt = "exported_at"
            case entryCount = "entry_count"
            case note
            case entries
        }
    }

    private struct Entry: Encodable {
        let id: String
        let createdAt: Date
        let mood: String
        let narrativeStyle: String
        let note: String?
        let aiNarrative: String?
        let isFavorite: Bool
        let photoFileName: String?

        init(entry: JournalEntry) {
            id = entry.id.uuidString
            createdAt = entry.createdAt
            mood = entry.mood.rawValue
            narrativeStyle = entry.narrativeStyle.rawValue
            note = entry.rawNote
            aiNarrative = entry.aiNarrative
            isFavorite = entry.isFavorite
            // File name only — a reference for a future import, never the image itself,
            // and never the surrounding directory structure.
            let name = (entry.photoPath as NSString).lastPathComponent
            photoFileName = name.isEmpty ? nil : name
        }

        enum CodingKeys: String, CodingKey {
            case id
            case createdAt = "created_at"
            case mood
            case narrativeStyle = "narrative_style"
            case note
            case aiNarrative = "ai_narrative"
            case isFavorite = "is_favorite"
            case photoFileName = "photo_file_name"
        }
    }
}
