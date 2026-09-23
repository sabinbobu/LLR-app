import Foundation
import UserNotifications

/// The in-app countdown dies the moment the phone is pocketed; a scheduled local notification is
/// the only thing that reaches the lifter mid-rest. In the foreground iOS suppresses it by default,
/// so it never doubles up with the in-app haptic.
enum RestNotifier {
    private static let id = "rest-timer"
    private static var center: UNUserNotificationCenter { .current() }

    static func schedule(after seconds: TimeInterval, exerciseName: String?) {
        guard seconds >= 1 else { return }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Rest over"
            content.body = exerciseName.map { "Time for your next set of \($0)." } ?? "Time for your next set."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    static func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}
