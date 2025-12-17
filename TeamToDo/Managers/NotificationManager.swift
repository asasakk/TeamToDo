import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for task: AppTask) {
        guard let taskId = task.id, let dueDate = task.dueDate, !task.isCompleted else { return }
        
        // Notify 1 day before, and on the day (e.g. 9 AM) or at exact time? 
        // User request: "When deadline approaches"
        // Let's schedule for the exact time for now, or 1 hour before.
        // If dueDate includes time, use it.
        
        // Remove existing notification for this task to avoid duplicates/updates
        removeNotification(for: taskId)
        
        let content = UNMutableNotificationContent()
        content.title = "タスクの期限が迫っています"
        content.body = task.title
        content.sound = .default
        
        // Trigger at due date
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "task-\(taskId)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeNotification(for taskId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task-\(taskId)"])
    }
}
