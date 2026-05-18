import Foundation

struct WeeklyRecap: Identifiable, Hashable {
    let id: UUID
    let entryIds: [UUID]
    let recap: String
    let generatedAt: Date
    let cached: Bool
}
