import XCTest
@testable import MemoryInk

/// The export is the one feature that writes a user's journal to a file they can send
/// anywhere, so its privacy guarantees are the ones worth pinning down in tests: the photo
/// itself never goes in, and neither does anything that could locate the person.
final class ExportServiceTests: XCTestCase {
    private var exportedURL: URL?

    override func tearDown() {
        if let exportedURL {
            try? FileManager.default.removeItem(at: exportedURL)
        }
        exportedURL = nil
        super.tearDown()
    }

    private let now = Date(timeIntervalSince1970: 1_776_000_000) // 2026-04-12 UTC

    private func makeEntry(
        createdAt: Date,
        photoPath: String = "originals/ABC-123.jpg",
        note: String? = "quiet morning",
        narrative: String? = "A slow start, and no hurry in it.",
        mood: MoodType = .peaceful,
        isFavorite: Bool = true
    ) -> JournalEntry {
        JournalEntry(
            id: UUID(),
            createdAt: createdAt,
            photoPath: photoPath,
            thumbnailPath: "thumbnails/ABC-123.jpg",
            mediumPreviewPath: "medium/ABC-123.jpg",
            rawNote: note,
            voicePath: nil,
            aiNarrative: narrative,
            mood: mood,
            narrativeStyle: .warm,
            syncStatus: .completed,
            aiGenerationDate: createdAt,
            isFavorite: isFavorite
        )
    }

    private func export(_ entries: [JournalEntry]) throws -> (json: [String: Any], text: String, data: Data) {
        let url = try ExportService.exportMetadata(entries: entries, now: now)
        exportedURL = url

        let data = try Data(contentsOf: url)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        return (json, text, data)
    }

    // MARK: - Privacy guarantees

    func testExportCarriesPhotoFileNameOnlyNeverAPath() throws {
        let result = try export([makeEntry(createdAt: now)])
        let entries = try XCTUnwrap(result.json["entries"] as? [[String: Any]])

        XCTAssertEqual(entries[0]["photo_file_name"] as? String, "ABC-123.jpg")
        XCTAssertFalse(result.text.contains("originals/"), "Directory structure must not be exported")
        XCTAssertFalse(result.text.contains("thumbnails/"))
        XCTAssertFalse(result.text.contains("medium/"))
    }

    func testExportContainsNoLocationOrCameraMetadata() throws {
        let result = try export([makeEntry(createdAt: now)])
        let lowercased = result.text.lowercased()

        for forbidden in ["gps", "latitude", "longitude", "exif", "altitude", "coordinate"] {
            XCTAssertFalse(lowercased.contains(forbidden), "Export must never contain \(forbidden)")
        }
    }

    func testExportContainsNoImageData() throws {
        let result = try export([makeEntry(createdAt: now)])

        XCTAssertFalse(result.text.lowercased().contains("base64"))
        // Metadata for one entry is on the order of hundreds of bytes; an embedded image
        // would be orders of magnitude larger.
        XCTAssertLessThan(result.data.count, 4_096)
    }

    func testEntryWithoutAPhotoExportsNoFileName() throws {
        let result = try export([makeEntry(createdAt: now, photoPath: "")])
        let entries = try XCTUnwrap(result.json["entries"] as? [[String: Any]])

        XCTAssertNil(entries[0]["photo_file_name"] as? String)
    }

    // MARK: - Document shape

    func testExportIsValidJSONWithTheExpectedEnvelope() throws {
        let result = try export([makeEntry(createdAt: now)])

        XCTAssertEqual(result.json["app"] as? String, "MemoryInk")
        XCTAssertEqual(result.json["format_version"] as? Int, ExportService.formatVersion)
        XCTAssertEqual(result.json["entry_count"] as? Int, 1)
        XCTAssertTrue((result.json["exported_at"] as? String)?.contains("T") == true, "Dates are ISO 8601")
    }

    func testEntryContentIsCarriedThrough() throws {
        let result = try export([makeEntry(createdAt: now)])
        let entry = try XCTUnwrap((result.json["entries"] as? [[String: Any]])?.first)

        XCTAssertEqual(entry["note"] as? String, "quiet morning")
        XCTAssertEqual(entry["ai_narrative"] as? String, "A slow start, and no hurry in it.")
        XCTAssertEqual(entry["mood"] as? String, "peaceful")
        XCTAssertEqual(entry["is_favorite"] as? Bool, true)
    }

    func testEntriesAreSortedOldestFirst() throws {
        let older = makeEntry(createdAt: now.addingTimeInterval(-86_400))
        let newer = makeEntry(createdAt: now)

        let result = try export([newer, older])
        let entries = try XCTUnwrap(result.json["entries"] as? [[String: Any]])
        let dates = entries.compactMap { $0["created_at"] as? String }

        XCTAssertEqual(dates, dates.sorted(), "A backup should read in the order it was lived")
    }

    // MARK: - Edge cases

    func testEmptyJournalThrowsRatherThanWritingAnEmptyFile() {
        XCTAssertThrowsError(try ExportService.exportMetadata(entries: [], now: now))
    }

    func testFileNameCarriesTheExportDate() {
        XCTAssertEqual(ExportService.fileName(for: now), "MemoryInk-Backup-2026-04-12.json")
    }
}
