import Foundation

/// One past year's memories for the date being revisited — the unit of the
/// year-over-year comparison on the On This Day screen.
struct OnThisDayYear: Identifiable, Hashable {
    let year: Int
    let yearsAgo: Int
    /// Newest first within the year.
    let entries: [JournalEntry]

    var id: Int { year }

    /// The entry that represents this year in the comparison strip: the first one
    /// with a photo, otherwise simply the first.
    var coverEntry: JournalEntry? {
        entries.first { !$0.thumbnailPath.isEmpty } ?? entries.first
    }

    var dominantMood: MoodType? {
        var counts: [MoodType: Int] = [:]
        for entry in entries {
            counts[entry.mood, default: 0] += 1
        }

        // Ties resolve by mood name so the strip doesn't flicker between equal moods.
        let ranked = counts.sorted { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value > rhs.value }
            return lhs.key.rawValue < rhs.key.rawValue
        }
        return ranked.first?.key
    }

    var yearsAgoLabel: String {
        switch yearsAgo {
        case ..<1: return "This year"
        case 1: return "1 year ago"
        default: return "\(yearsAgo) years ago"
        }
    }
}

@MainActor
final class OnThisDayService: ObservableObject {
    /// Flat, newest-first list — kept for callers that only need a count
    /// (e.g. `NotificationService.scheduleOnThisDayIfNeeded`).
    @Published private(set) var entries: [JournalEntry] = []
    /// The same memories grouped by year, most recent year first.
    @Published private(set) var years: [OnThisDayYear] = []
    /// 1-based day of the journey (first memory ever = Day 1), or `nil` for an empty journal.
    @Published private(set) var journeyDayNumber: Int?

    private let repository: JournalEntryRepository
    private let calendar: Calendar

    init(repository: JournalEntryRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    func refresh(for date: Date = Date()) {
        let currentYear = calendar.component(.year, from: date)
        let matches = repository.entriesMatchingMonthAndDay(
            date,
            excludingYear: currentYear,
            calendar: calendar
        )

        entries = matches
        years = Self.group(matches, currentYear: currentYear, calendar: calendar)
        journeyDayNumber = repository.firstEntryDate.map {
            MilestoneService.dayNumber(from: $0, to: date, calendar: calendar)
        }
    }

    private static func group(
        _ entries: [JournalEntry],
        currentYear: Int,
        calendar: Calendar
    ) -> [OnThisDayYear] {
        Dictionary(grouping: entries) { calendar.component(.year, from: $0.createdAt) }
            .map { year, entries in
                OnThisDayYear(
                    year: year,
                    yearsAgo: currentYear - year,
                    entries: entries.sorted { $0.createdAt > $1.createdAt }
                )
            }
            .sorted { $0.year > $1.year }
    }
}
