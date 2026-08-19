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
/// the handful of colours a widget needs are restated here.
///
/// **Keep these in step with `Common/Theme/Colors.swift` by hand.** There is no compiler link
/// between the two, so a palette change in the app silently leaves the widget on the old look —
/// the widget sits on the Home Screen next to the app icon, where a stale palette is obvious.
///
/// Values mirror the Part C *Cinematic Dark* palette, including its light/dark pairs: a widget
/// adopts the system appearance like any other view, so fixed colours would misread in one of them.
private enum WidgetPalette {
    static let ink = adaptive(light: rgb(0.090, 0.086, 0.102), dark: rgb(0.957, 0.949, 0.937))
    static let secondaryInk = adaptive(light: rgb(0.333, 0.325, 0.310), dark: rgb(0.639, 0.631, 0.620))

    static func gradient(for moodRawValue: String?) -> [Color] {
        let tint: Color
        switch moodRawValue {
        case "peaceful": tint = adaptive(light: rgb(0.223, 0.499, 0.453), dark: rgb(0.340, 0.760, 0.690))
        case "nostalgic": tint = adaptive(light: rgb(0.530, 0.399, 0.646), dark: rgb(0.730, 0.550, 0.890))
        case "happy": tint = adaptive(light: rgb(0.543, 0.440, 0.206), dark: rgb(0.950, 0.770, 0.360))
        case "proud": tint = adaptive(light: rgb(0.659, 0.374, 0.354), dark: rgb(0.950, 0.540, 0.510))
        case "sad": tint = adaptive(light: rgb(0.306, 0.466, 0.633), dark: rgb(0.440, 0.670, 0.910))
        case "reflective": tint = adaptive(light: rgb(0.419, 0.434, 0.669), dark: rgb(0.570, 0.590, 0.910))
        default: tint = adaptive(light: rgb(0.472, 0.449, 0.434), dark: rgb(0.620, 0.590, 0.570))
        }

        return [tint.opacity(0.85), tint.opacity(0.35)]
    }

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }

    private static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
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
