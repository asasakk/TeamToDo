import Foundation
import FirebaseFirestore

struct AppTask: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String?
    var dueDate: Date?
    var isCompleted: Bool
    var assignedTo: String?
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date?
    
    // Client-side only property for Collection Group queries
    var projectId: String?
    
    // CodingKeys removed to allow @DocumentID to work correctly.
}
