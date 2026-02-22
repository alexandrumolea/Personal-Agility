import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for client: Client) {
        // Cancel existing notification for this client first
        cancelNotification(for: client)
        
        guard let nextDate = client.nextCheckInDate, client.frequency != .none else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Client Contact Reminder"
        content.body = "It's time to reach out to \(client.name)"
        content.sound = .default
        
        // Target 8:30 AM on the calculated nextDate
        var components = Calendar.current.dateComponents([.year, .month, .day], from: nextDate)
        components.hour = 8
        components.minute = 30
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "contact-\(client.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(for client: Client) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["contact-\(client.id.uuidString)"])
    }
}
