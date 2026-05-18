import Foundation

final class AIUsageTracker {
    private enum Key {
        static let narrativeUsageDate = "ai_usage_narrative_date"
        static let narrativeUsageCount = "ai_usage_narrative_count"
        static let recapUsageDate = "ai_usage_recap_date"
        static let recapUsageCount = "ai_usage_recap_count"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    var narrativeRequestsToday: Int {
        count(forDateKey: Key.narrativeUsageDate, countKey: Key.narrativeUsageCount)
    }

    var recapRequestsToday: Int {
        count(forDateKey: Key.recapUsageDate, countKey: Key.recapUsageCount)
    }

    func canGenerateNarrative(limit: Int) -> Bool {
        narrativeRequestsToday < limit
    }

    func recordNarrativeRequest() {
        increment(dateKey: Key.narrativeUsageDate, countKey: Key.narrativeUsageCount)
    }

    func recordRecapRequest() {
        increment(dateKey: Key.recapUsageDate, countKey: Key.recapUsageCount)
    }

    private func count(forDateKey dateKey: String, countKey: String) -> Int {
        guard
            let storedDate = defaults.object(forKey: dateKey) as? Date,
            calendar.isDateInToday(storedDate)
        else {
            return 0
        }

        return defaults.integer(forKey: countKey)
    }

    private func increment(dateKey: String, countKey: String) {
        let currentCount = count(forDateKey: dateKey, countKey: countKey)
        defaults.set(Date(), forKey: dateKey)
        defaults.set(currentCount + 1, forKey: countKey)
    }
}
