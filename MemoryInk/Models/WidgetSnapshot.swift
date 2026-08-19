import Foundation

/// The small amount of data the Home/Lock Screen widgets are allowed to see.
///
/// **This file is compiled into both the app and the widget extension**, and it is the only
/// thing that crosses between them. The widget runs in its own process and cannot read Core
/// Data, so the app writes this snapshot into the shared App Group container whenever the
/// journal changes and the widget reads it back.
///
/// Deliberately tiny: a mood, a day count, a short line, and a thumbnail. No note text beyond
/// what already appears on the card, no location, no photo original — a widget sits on a screen
/// other people can see over your shoulder.
struct WidgetSnapshot: Codable, Equatable {
    /// `MoodType.rawValue` — kept as a string so the widget target doesn't need the app's models.
    let moodRawValue: String
    let moodTitle: String
    /// The latest memory's narrative, trimmed to something a widget can show.
    let snippet: String?
    let latestMemoryDate: Date?
    /// 1-based day of the journey (first memory = Day 1).
    let dayNumber: Int?
    let entryCount: Int
    /// File name of the thumbnail copy inside the App Group container, if any.
    let thumbnailFileName: String?

    static let empty = WidgetSnapshot(
        moodRawValue: "peaceful",
        moodTitle: "Peaceful",
        snippet: nil,
        latestMemoryDate: nil,
        dayNumber: nil,
        entryCount: 0,
        thumbnailFileName: nil
    )
}

/// Where the app and the widget agree to meet.
enum WidgetSharedStore {
    /// Must match the App Groups entitlement on **both** targets.
    static let appGroupId = "group.com.memoryink.app"
    static let snapshotFileName = "widget-snapshot.json"
    static let thumbnailFileName = "widget-thumbnail.jpg"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    static var snapshotURL: URL? {
        containerURL?.appendingPathComponent(snapshotFileName)
    }

    static var thumbnailURL: URL? {
        containerURL?.appendingPathComponent(thumbnailFileName)
    }

    /// Reads the snapshot the app last wrote. Returns `nil` when the App Group isn't reachable
    /// or nothing has been written yet — the widget shows its own empty state in that case.
    static func readSnapshot() -> WidgetSnapshot? {
        guard let snapshotURL, let data = try? Data(contentsOf: snapshotURL) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}
