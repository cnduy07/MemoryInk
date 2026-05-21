import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var displayMonth: Date = Date()
    @Published var selectedDate: Date?

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func entriesForDay(_ date: Date, in entries: [JournalEntry]) -> [JournalEntry] {
        entries
            .filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func primaryMood(for date: Date, in entries: [JournalEntry]) -> MoodType? {
        entriesForDay(date, in: entries).first?.mood
    }

    func entriesForVisibleRange(in entries: [JournalEntry]) -> [JournalEntry] {
        if let selectedDate {
            return entriesForDay(selectedDate, in: entries)
        }

        return entries
            .filter { calendar.isDate($0.createdAt, equalTo: displayMonth, toGranularity: .month) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayMonth),
              let dayRange = calendar.range(of: .day, in: .month, for: displayMonth) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingEmptyDays = max(weekday - calendar.firstWeekday, 0)
        let days = dayRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start)
        }

        return Array(repeating: nil, count: leadingEmptyDays) + days
    }

    func navigateMonth(by offset: Int) {
        displayMonth = calendar.date(byAdding: .month, value: offset, to: displayMonth) ?? displayMonth
        selectedDate = nil
    }
}
