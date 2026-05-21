import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    @Published private(set) var isEnabled: Bool = false
    @Published var reminderTime: Date

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private let reminderID = "memoryink.daily.reminder"

    init() {
        isEnabled = defaults.bool(forKey: "notification_enabled")
        let stored = defaults.object(forKey: "notification_time") as? Date
        reminderTime = stored ?? Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    }

    func requestAndEnable() async {
        let granted = try? await center.requestAuthorization(options: [.alert, .sound])
        guard granted == true else { return }

        isEnabled = true
        defaults.set(true, forKey: "notification_enabled")
        schedule()
    }

    func disable() {
        isEnabled = false
        defaults.set(false, forKey: "notification_enabled")
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])
    }

    func updateTime(_ date: Date) {
        reminderTime = date
        defaults.set(date, forKey: "notification_time")
        if isEnabled {
            schedule()
        }
    }

    func scheduleOnThisDayIfNeeded(entryCount: Int) async {
        guard entryCount > 0 else { return }

        let todayKey = "on_this_day_notif_\(dateKey())"
        guard !defaults.bool(forKey: todayKey) else { return }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        defaults.set(true, forKey: todayKey)

        let content = UNMutableNotificationContent()
        content.title = "MemoryInk"
        content.body = "You have a memory from this day."
        content.sound = .default

        let trigger: UNNotificationTrigger
        let calendar = Calendar.current
        let targetDate = calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()

        if targetDate <= Date() {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        } else {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: "memoryink.on-this-day.\(dateKey())",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private func schedule() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])

        let content = UNMutableNotificationContent()
        content.title = "MemoryInk"
        content.body = "Time to capture a moment worth keeping."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        center.add(request)
    }

    private func dateKey() -> String {
        DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
    }
}
