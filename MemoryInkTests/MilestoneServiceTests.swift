import XCTest
@testable import MemoryInk

/// Journey milestones are one-off moments the user can never see twice, so the rules that
/// matter most are the ones about *not* firing: not again, not for an existing user who
/// already saw them, not in a queue after a long absence.
final class MilestoneServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var calendar: Calendar!

    private let firstEntry = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01 UTC

    override func setUp() {
        super.setUp()
        suiteName = "milestone-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)

        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeService() -> MilestoneService {
        MilestoneService(defaults: defaults, calendar: calendar)
    }

    private func date(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: iso)!
    }

    // MARK: - Not firing

    func testEmptyJournalNeverFires() {
        let service = makeService()

        XCTAssertNil(service.check(entryCount: 0, firstEntryDate: nil, now: date("2025-06-01")))
        XCTAssertNil(service.check(entryCount: 0, firstEntryDate: firstEntry, now: date("2025-06-01")))
    }

    func testAMilestoneFiresOnlyOnce() {
        let service = makeService()

        XCTAssertNotNil(service.check(entryCount: 10, firstEntryDate: firstEntry, now: date("2024-01-05")))
        XCTAssertNil(service.check(entryCount: 10, firstEntryDate: firstEntry, now: date("2024-01-05")))
        XCTAssertNil(service.check(entryCount: 11, firstEntryDate: firstEntry, now: date("2024-01-05")))
    }

    /// Users who already saw the old count-only milestones must not see them a second time
    /// when they update — the new code reuses the original `milestone_shown_*` keys.
    func testExistingUsersDoNotReseeOldMilestones() {
        [10, 25, 50].forEach { defaults.set(true, forKey: "milestone_shown_\($0)") }
        let service = makeService()

        XCTAssertNil(service.check(entryCount: 60, firstEntryDate: firstEntry, now: date("2024-01-15")))
    }

    // MARK: - Firing

    /// The old implementation matched an exact count, so a user who added several entries at
    /// once could skip a milestone permanently.
    func testThresholdIsReachedOrPassedNotExactMatch() {
        let service = makeService()

        XCTAssertEqual(
            service.check(entryCount: 27, firstEntryDate: firstEntry, now: date("2024-01-20")),
            "25 memories captured. This journal is becoming a piece of you."
        )
    }

    /// A day-count or anniversary moment arrives with time passing, not with a new entry.
    func testTimeMilestoneFiresWithNoNewEntries() {
        let service = makeService()

        XCTAssertNil(service.check(entryCount: 5, firstEntryDate: firstEntry, now: date("2024-01-10")))
        XCTAssertEqual(
            service.check(entryCount: 5, firstEntryDate: firstEntry, now: date("2024-01-30")),
            "A month of MemoryInk. Small moments, quietly kept."
        )
        XCTAssertEqual(
            service.check(entryCount: 5, firstEntryDate: firstEntry, now: date("2025-01-01")),
            "One year since your first memory. A whole season of you, kept."
        )
    }

    /// Returning after a long gap should feel like one quiet moment, not a backlog of toasts.
    func testSeveralMilestonesAtOnceSurfaceOnlyTheDeepest() {
        let service = makeService()

        XCTAssertEqual(
            service.check(entryCount: 120, firstEntryDate: firstEntry, now: date("2024-06-01")),
            "100 moments held quietly. Remarkable."
        )
        XCTAssertNil(service.check(entryCount: 120, firstEntryDate: firstEntry, now: date("2024-06-01")))
    }

    // MARK: - Day numbering

    func testDayNumberingIsOneBased() {
        XCTAssertEqual(MilestoneService.dayNumber(from: firstEntry, to: firstEntry, calendar: calendar), 1)
        XCTAssertEqual(MilestoneService.dayNumber(from: firstEntry, to: date("2024-01-02"), calendar: calendar), 2)
    }

    /// A device clock set backwards must not produce a negative or zero day count.
    func testBackwardsClockClampsToDayOne() {
        XCTAssertEqual(
            MilestoneService.dayNumber(from: date("2024-01-02"), to: firstEntry, calendar: calendar),
            1
        )
    }
}
