import SwiftUI
import UIKit
import WidgetKit

/// Home and Lock Screen widgets, reading the snapshot the app leaves in the shared App Group
/// container. This process has no access to Core Data and no network of its own.
struct MemoryInkWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MemoryInkWidget", provider: SnapshotProvider()) { entry in
            MemoryInkWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("MemoryInk")
        .description("Your latest memory, and how long you've been keeping them.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: Date(), snapshot: WidgetSharedStore.readSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: Date(), snapshot: WidgetSharedStore.readSnapshot())
        // The app reloads timelines whenever the journal changes; this is just a daily backstop
        // so the day counter rolls over on its own.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)

        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Views

struct MemoryInkWidgetView: View {
    let snapshot: WidgetSnapshot?

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .systemMedium:
            medium
        default:
            small
        }
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(moodTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(hasPhoto ? .white : WidgetPalette.ink)

            if let dayLabel {
                Text(dayLabel)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(hasPhoto ? .white.opacity(0.78) : WidgetPalette.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .widgetBackgroundCompat(background)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(moodTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(hasPhoto ? .white : WidgetPalette.ink)

            if let snippet = snapshot?.snippet {
                Text(snippet)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(hasPhoto ? .white.opacity(0.92) : WidgetPalette.ink)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            if let dayLabel {
                Text(dayLabel)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(hasPhoto ? .white.opacity(0.72) : WidgetPalette.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .widgetBackgroundCompat(background)
    }

    // MARK: Lock Screen

    private var circular: some View {
        VStack(spacing: 1) {
            Image(systemName: "book.closed")
                .font(.system(size: 12, weight: .medium))

            Text(snapshot?.dayNumber.map(String.init) ?? "–")
                .font(.system(size: 15, weight: .semibold))
        }
        .widgetBackgroundCompat(Color.clear)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(moodTitle)
                .font(.system(size: 13, weight: .semibold))

            if let snippet = snapshot?.snippet {
                Text(snippet)
                    .font(.system(size: 12, weight: .regular))
                    .lineLimit(2)
            } else if let dayLabel {
                Text(dayLabel)
                    .font(.system(size: 12, weight: .regular))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetBackgroundCompat(Color.clear)
    }

    // MARK: Pieces

    @ViewBuilder
    private var background: some View {
        if let image = thumbnail {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.62)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        } else {
            LinearGradient(
                colors: WidgetPalette.gradient(for: snapshot?.moodRawValue),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var thumbnail: UIImage? {
        guard snapshot?.thumbnailFileName != nil,
              let url = WidgetSharedStore.thumbnailURL,
              let data = try? Data(contentsOf: url) else { return nil }

        return UIImage(data: data)
    }

    private var hasPhoto: Bool { thumbnail != nil }

    private var moodTitle: String {
        guard let snapshot, snapshot.entryCount > 0 else { return "MemoryInk" }
        return snapshot.moodTitle
    }

    private var dayLabel: String? {
        guard let snapshot else { return nil }
        guard snapshot.entryCount > 0 else { return "Your first memory awaits" }
        guard let day = snapshot.dayNumber else { return nil }
        return "Day \(day)"
    }
}

/// The widget target can't see the app's `MemoryInkColors` (that lives in the app target), so
/// the handful of colours a widget needs are restated here, matching the app's palette.
private enum WidgetPalette {
    static let ink = Color(red: 0.135, green: 0.116, blue: 0.098)
    static let secondaryInk = Color(red: 0.396, green: 0.350, blue: 0.294)

    static func gradient(for moodRawValue: String?) -> [Color] {
        let tint: Color
        switch moodRawValue {
        case "peaceful": tint = Color(red: 0.25, green: 0.60, blue: 0.54)
        case "nostalgic": tint = Color(red: 0.58, green: 0.38, blue: 0.70)
        case "happy": tint = Color(red: 0.88, green: 0.62, blue: 0.24)
        case "proud": tint = Color(red: 0.78, green: 0.39, blue: 0.42)
        case "sad": tint = Color(red: 0.28, green: 0.52, blue: 0.72)
        case "reflective": tint = Color(red: 0.38, green: 0.40, blue: 0.68)
        default: tint = Color(red: 0.56, green: 0.50, blue: 0.44)
        }

        return [tint.opacity(0.85), tint.opacity(0.35)]
    }
}

private extension View {
    /// iOS 17 requires a widget's background to be declared with `containerBackground`;
    /// earlier versions want it drawn behind the content instead.
    @ViewBuilder
    func widgetBackgroundCompat(_ background: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { background }
        } else {
            padding(14)
                .background(background)
        }
    }
}
