import Foundation

/// A one-off moment in the user's journey worth quietly acknowledging.
///
/// Two kinds exist: how much has been kept (entry counts) and how long it's been kept
/// (days and anniversaries since the very first memory). These are anniversaries, not
/// streaks — nothing resets, nothing can be broken, nothing is scored.
struct JourneyMilestone: Equatable {
    /// Stable `UserDefaults` suffix. Never change an existing one — users who already
    /// saw that milestone would see it a second time.
    let key: String
    let message: String
    let isReached: (_ entryCount: Int, _ dayNumber: Int, _ years: Int) -> Bool

    static func == (lhs: JourneyMilestone, rhs: JourneyMilestone) -> Bool {
        lhs.key == rhs.key
    }
}

final class MilestoneService {
    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    /// Returns the message for the deepest milestone the user has just reached, or `nil`.
    ///
    /// Called both when an entry is saved and when the app opens — a day-count or anniversary
    /// milestone arrives with the passing of time, not with a new memory.
    func check(entryCount: Int, firstEntryDate: Date?, now: Date = Date()) -> String? {
        guard entryCount > 0, let firstEntryDate else { return nil }

        let dayNumber = Self.dayNumber(from: firstEntryDate, to: now, calendar: calendar)
        let years = calendar.dateComponents([.year], from: firstEntryDate, to: now).year ?? 0

        let reached = Self.milestones.filter { $0.isReached(entryCount, dayNumber, years) }
        guard let deepestUnshown = reached.last(where: { !hasShown($0) }) else { return nil }

        // Mark every reached milestone as shown, not just the one being surfaced, so a user
        // who returns after a long gap gets one quiet moment instead of a queue of toasts.
        reached.forEach { markShown($0) }

        return deepestUnshown.message
    }

    /// 1-based day of the journey: the day of the first memory is Day 1.
    static func dayNumber(from firstEntryDate: Date, to now: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: firstEntryDate)
        let today = calendar.startOfDay(for: now)
        let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(elapsed, 0) + 1
    }

    private func hasShown(_ milestone: JourneyMilestone) -> Bool {
        defaults.bool(forKey: "milestone_shown_\(milestone.key)")
    }

    private func markShown(_ milestone: JourneyMilestone) {
        defaults.set(true, forKey: "milestone_shown_\(milestone.key)")
    }

    private static func count(_ threshold: Int, _ message: String) -> JourneyMilestone {
        // Keys stay bare numbers so the original `milestone_shown_10` … `_250` keys keep working.
        JourneyMilestone(key: "\(threshold)", message: message) { entryCount, _, _ in
            entryCount >= threshold
        }
    }

    private static func day(_ threshold: Int, _ message: String) -> JourneyMilestone {
        JourneyMilestone(key: "day_\(threshold)", message: message) { _, dayNumber, _ in
            dayNumber >= threshold
        }
    }

    private static func anniversary(_ threshold: Int, _ message: String) -> JourneyMilestone {
        JourneyMilestone(key: "year_\(threshold)", message: message) { _, _, years in
            years >= threshold
        }
    }

    /// Ordered shallowest → deepest. When several are reached at once, the last one wins.
    private static let milestones: [JourneyMilestone] = [
        count(10, "10 moments worth keeping. You're building something real."),
        count(25, "25 memories captured. This journal is becoming a piece of you."),
        day(30, "A month of MemoryInk. Small moments, quietly kept."),
        count(50, "50 memories. That's a story only you could tell."),
        day(100, "100 days of MemoryInk. Look how much you've held onto."),
        count(100, "100 moments held quietly. Remarkable."),
        anniversary(1, "One year since your first memory. A whole season of you, kept."),
        count(250, "250 memories. MemoryInk is honoured to hold them."),
        day(500, "500 days since your first memory. What a stretch of life."),
        anniversary(2, "Two years since your first memory. Time has been generous."),
        count(500, "500 memories. An entire library of your own."),
        day(1000, "1,000 days of MemoryInk. A long, gentle record of you."),
        anniversary(3, "Three years of memories. This is a real archive now."),
        anniversary(4, "Four years since your first memory. Still here, still noticing."),
        anniversary(5, "Five years of MemoryInk. Thank you for keeping the light on.")
    ]
}
