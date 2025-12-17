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
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case dueDate
        case isCompleted
        case assignedTo
        case createdBy
        case createdAt
        case updatedAt
    }
}
