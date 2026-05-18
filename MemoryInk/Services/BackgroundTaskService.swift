import BackgroundTasks
import Foundation

final class BackgroundTaskService {
    static let weeklyRecapIdentifier = "com.memoryink.app.weekly-recap"

    func registerStubs() {
        // Stub only for Phase 2. Actual scheduling requires Info.plist identifiers and human approval.
    }

    func handleWeeklyRecap(task: BGTask) {
        task.setTaskCompleted(success: true)
    }
}
