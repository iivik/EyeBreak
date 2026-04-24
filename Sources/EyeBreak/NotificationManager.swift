import Foundation
import UserNotifications
import ServiceManagement

// MARK: - NotificationManager
// Handles: system break-warning notifications + DND detection + login item

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    private override init() { super.init() }

    private let warningID = "com.eyebreak.warning"

    /// UNUserNotificationCenter requires a real .app bundle — not available in CLI debug builds.
    private var isBundled: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    // MARK: - Permission

    func requestPermission() {
        guard isBundled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Break Warning Notification

    /// Call this when the T-60s warning fires (only if user has enabled it).
    func postBreakWarning() {
        guard isBundled, AppSettings.shared.showInNotifCenter else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let content   = UNMutableNotificationContent()
            content.title = "Eye break in 1 minute"
            content.body  = "20 feet · 20 seconds · 20-20-20 rule"
            content.sound = .default

            let req = UNNotificationRequest(identifier: self.warningID,
                                            content:    content,
                                            trigger:    nil)
            UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
        }
    }

    func cancelBreakWarning() {
        guard isBundled else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [warningID])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [warningID])
    }

    // MARK: - DND / Focus Detection

    /// Returns true when a Focus / Do Not Disturb mode is currently active.
    /// Reads ~/Library/DoNotDisturb/DB/Assertions.json — no entitlement needed
    /// for non-sandboxed apps. Falls back to false (never suppress) on failure.
    func isDNDActive() -> Bool {
        let path = (NSHomeDirectory() as NSString)
            .appendingPathComponent("Library/DoNotDisturb/DB/Assertions.json")
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json["data"] as? [[String: Any]],
              let first = rows.first,
              let records = first["storeAssertionRecords"] as? [[String: Any]] else {
            return false
        }
        return !records.isEmpty
    }

    // MARK: - Start at Login

    func applyLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Fails gracefully when running outside a bundled .app (e.g. debug CLI build)
            print("[LoginItem] \(error.localizedDescription)")
        }
    }

    /// Returns the actual SMAppService status (not just the stored pref).
    var loginItemIsActive: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
