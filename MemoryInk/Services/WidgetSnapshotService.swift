import Foundation
import UIKit
import WidgetKit

/// Writes the widget's snapshot into the shared App Group container.
///
/// The Core Data store is **not** moved or shared — the widget never touches it. The app simply
/// leaves a small file and one thumbnail copy where the widget can pick them up, so a journal
/// that already exists on a device is never migrated or put at risk.
enum WidgetSnapshotService {
    /// Rebuilds the snapshot from the current journal and asks WidgetKit to refresh.
    /// Cheap enough to call whenever the journal changes; silently does nothing when the App
    /// Group isn't configured (e.g. a simulator build without the entitlement).
    static func update(entries: [JournalEntry], now: Date = Date()) {
        guard let containerURL = WidgetSharedStore.containerURL,
              let snapshotURL = WidgetSharedStore.snapshotURL else { return }

        let latest = entries.max { $0.createdAt < $1.createdAt }
        let firstDate = entries.min { $0.createdAt < $1.createdAt }?.createdAt

        let thumbnailName = latest.flatMap { copyThumbnail(for: $0, into: containerURL) }

        let snapshot = WidgetSnapshot(
            moodRawValue: latest?.mood.rawValue ?? WidgetSnapshot.empty.moodRawValue,
            moodTitle: latest?.mood.title ?? WidgetSnapshot.empty.moodTitle,
            snippet: latest.flatMap { snippet(for: $0) },
            latestMemoryDate: latest?.createdAt,
            dayNumber: firstDate.map { MilestoneService.dayNumber(from: $0, to: now) },
            entryCount: entries.count,
            thumbnailFileName: thumbnailName
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: snapshotURL, options: .atomic)

        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Removes everything the widget can see — used when the journal empties out.
    static func clear() {
        [WidgetSharedStore.snapshotURL, WidgetSharedStore.thumbnailURL]
            .compactMap { $0 }
            .forEach { try? FileManager.default.removeItem(at: $0) }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func snippet(for entry: JournalEntry) -> String? {
        guard let narrative = entry.aiNarrative?.trimmingCharacters(in: .whitespacesAndNewlines),
              !narrative.isEmpty else { return nil }

        let limit = 90
        guard narrative.count > limit else { return narrative }
        return String(narrative.prefix(limit)).trimmingCharacters(in: .whitespaces) + "…"
    }

    /// Copies the thumbnail (never the original or the medium preview) into the container.
    private static func copyThumbnail(for entry: JournalEntry, into containerURL: URL) -> String? {
        guard let image = ImagePipelineService.image(forRelativePath: entry.thumbnailPath),
              let data = image.jpegData(compressionQuality: 0.85) else { return nil }

        let destination = containerURL.appendingPathComponent(WidgetSharedStore.thumbnailFileName)
        guard (try? data.write(to: destination, options: .atomic)) != nil else { return nil }

        return WidgetSharedStore.thumbnailFileName
    }
}
