import Foundation

final class MilestoneService {
    private let defaults = UserDefaults.standard
    private let milestones: [Int] = [10, 25, 50, 100, 250]

    func checkMilestone(entryCount: Int) -> String? {
        guard milestones.contains(entryCount) else { return nil }

        let key = "milestone_shown_\(entryCount)"
        guard !defaults.bool(forKey: key) else { return nil }

        defaults.set(true, forKey: key)
        return message(for: entryCount)
    }

    private func message(for count: Int) -> String {
        switch count {
        case 10:
            return "10 moments worth keeping. You're building something real."
        case 25:
            return "25 memories captured. This journal is becoming a piece of you."
        case 50:
            return "50 memories. That's a story only you could tell."
        case 100:
            return "100 moments held quietly. Remarkable."
        case 250:
            return "250 memories. MemoryInk is honoured to hold them."
        default:
            return "\(count) memories. Keep going."
        }
    }
}
