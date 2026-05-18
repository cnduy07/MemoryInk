import Foundation

@MainActor
final class OnThisDayService: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []

    private let repository: JournalEntryRepository
    private let calendar: Calendar

    init(repository: JournalEntryRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    func refresh(for date: Date = Date()) {
        entries = repository.entriesMatchingMonthAndDay(
            date,
            excludingYear: calendar.component(.year, from: date)
        )
    }
}
