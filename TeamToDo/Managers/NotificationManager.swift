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
    
    // Default notification time: managed by UserDefaults, default 6
    private var defaultHoursBefore: Int {
        UserDefaults.standard.integer(forKey: "notificationHoursBefore") == 0 ? 6 : UserDefaults.standard.integer(forKey: "notificationHoursBefore")
    }
    
    func scheduleNotification(for task: AppTask) {
        guard let taskId = task.id, let dueDate = task.dueDate, !task.isCompleted else { 
            // If task is completed or no due date, ensure no notification exists
            if let taskId = task.id {
                removeNotification(for: taskId)
            }
            return 
        }
        
        let identifier = "task-\(taskId)"
        
        // Calculate trigger date (6 hours before)
        // If due date is passed or less than 6 hours away, this might be immediate or skipped.
        // Let's schedule it if the time is in the future.
        let triggerDate = Calendar.current.date(byAdding: .hour, value: -defaultHoursBefore, to: dueDate) ?? dueDate
        
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "タスクの期限が迫っています"
        content.body = "\(task.title) (期限: \(formatDate(dueDate)))"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeNotification(for taskId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task-\(taskId)"])
    }
    
    // Sync all notifications based on the latest task list
    func syncTaskNotifications(tasks: [AppTask]) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            
            // 1. Identify valid task IDs that should have notifications
            let validTaskIds = Set(tasks.compactMap { $0.id })
            
            // 2. Schedule/Update notifications for current tasks
            for task in tasks {
                self.scheduleNotification(for: task)
            }
            
            // 3. Remove notifications for tasks that no longer exist or are not in the list
            //    (e.g. unassigned, deleted)
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix("task-") }
                .compactMap { request -> String? in
                    let idPart = String(request.identifier.dropFirst(5)) // remove "task-"
                    if !validTaskIds.contains(idPart) {
                        return request.identifier
                    }
                    return nil
                }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
