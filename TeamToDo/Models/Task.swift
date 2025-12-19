import Foundation
import FirebaseFirestore

enum TaskPriority: String, Codable, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "blue"
        }
    }
}

struct AppTask: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var title: String
    var description: String?
    var dueDate: Date?
    var isCompleted: Bool
    var assignedTo: String?
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date?
    var priority: TaskPriority = .medium
    var subtasks: [SubTask]? = []
    
    // Client-side only property for Collection Group queries
    var projectId: String?
}

struct SubTask: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var isCompleted: Bool = false
    
    // CodingKeys removed to allow @DocumentID to work correctly.
}
