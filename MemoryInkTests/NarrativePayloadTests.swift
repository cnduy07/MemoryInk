import XCTest
@testable import MemoryInk

/// `scene_labels` is what the server prompt treats as observed fact about a memory, so what
/// goes in it decides what the AI says — and, more importantly, what it can never see.
final class NarrativePayloadTests: XCTestCase {
    private func makeEntry(
        note: String? = nil,
        mood: MoodType = .happy,
        style: NarrativeStyle = .warm
    ) -> JournalEntry {
        JournalEntry(
            id: UUID(),
            createdAt: Date(),
            photoPath: "originals/ABC-123.jpg",
            thumbnailPath: "thumbnails/ABC-123.jpg",
            mediumPreviewPath: "medium/ABC-123.jpg",
            rawNote: note,
            voicePath: "voice/ABC-123.m4a",
            aiNarrative: nil,
            mood: mood,
            narrativeStyle: style,
            syncStatus: .pending,
            aiGenerationDate: nil,
            isFavorite: false
        )
    }

    /// Regression test — 2026-08-19.
    ///
    /// The narrative style used to be included in `scene_labels`. The server prompt says
    /// "use only facts from scene_labels", so the model read the word "warm" as something
    /// observed about the scene and echoed it into nearly every narrative — even though the
    /// same prompt explicitly bans that word. Style is a tone directive; it travels in its
    /// own `narrative_style` field and must never appear here.
    func testSceneLabelsNeverContainTheNarrativeStyle() {
        for style in [NarrativeStyle.warm, .minimal, .reflective] {
            let labels = NarrativeGenerationService.semanticLabels(for: makeEntry(style: style))

            XCTAssertFalse(
                labels.contains(style.rawValue),
                "Narrative style '\(style.rawValue)' leaked into scene_labels — the model will repeat it"
            )
        }
    }

    /// The privacy rule the whole product rests on: the payload is built from mood and the
    /// user's own words only. The entry's storage paths — photo, thumbnail, preview, voice —
    /// must never be read from, however tempting they look like free "context".
    ///
    /// Note text itself *is* allowed to travel (mood, note and vision labels are the agreed
    /// payload), so this asserts on the path fields specifically rather than banning words
    /// that a user might legitimately write in their own note.
    func testSceneLabelsAreNeverBuiltFromStoragePaths() {
        let entry = makeEntry(note: "A calm evening at the harbour with coffee")
        let joined = NarrativeGenerationService.semanticLabels(for: entry).joined(separator: " ")

        for path in [entry.photoPath, entry.thumbnailPath, entry.mediumPreviewPath, entry.voicePath ?? ""] {
            let identifier = (path as NSString).deletingPathExtension
            XCTAssertFalse(joined.contains(identifier), "Storage path '\(path)' leaked into the AI payload")
        }

        for fragment in ["ABC-123", "originals", "thumbnails", "medium/", "voice", ".jpg", ".m4a", "/"] {
            XCTAssertFalse(joined.contains(fragment), "'\(fragment)' must never reach the AI payload")
        }
    }

    func testMoodIsAlwaysIncluded() {
        let labels = NarrativeGenerationService.semanticLabels(for: makeEntry(mood: .nostalgic))

        XCTAssertEqual(labels.first, "nostalgic")
    }

    func testNoteContributesMeaningfulWordsOnly() {
        let labels = NarrativeGenerationService.semanticLabels(
            for: makeEntry(note: "A calm evening at the harbour with coffee")
        )

        XCTAssertTrue(labels.contains("evening"))
        XCTAssertTrue(labels.contains("harbour"))
        XCTAssertFalse(labels.contains("at"), "Short filler words carry no meaning for the model")
        XCTAssertFalse(labels.contains("the"))
    }

    func testLabelsAreDeduplicated() {
        let labels = NarrativeGenerationService.semanticLabels(
            for: makeEntry(note: "happy happy morning", mood: .happy)
        )

        XCTAssertEqual(Set(labels).count, labels.count)
    }

    func testEntryWithNoNoteStillProducesAValidPayload() {
        let labels = NarrativeGenerationService.semanticLabels(for: makeEntry(note: nil))

        XCTAssertEqual(labels, ["happy"])
    }
}
