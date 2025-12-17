import Foundation
import FirebaseFirestore

struct Project: Identifiable, Codable {
    @DocumentID var id: String?
    var orgId: String
    var name: String
    var description: String?
    var memberIds: [String]
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case orgId
        case name
        case description
        case memberIds
        case createdAt
    }
}
