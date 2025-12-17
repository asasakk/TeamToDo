import Foundation
import FirebaseFirestore

struct TeamTask: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var createdBy: String
    var assignedTo: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted = "is_completed"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case assignedTo = "assigned_to"
    }
}
