import Foundation
import FirebaseFirestore

struct Organization: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var memberIds: [String]
    var inviteCode: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ownerId
        case memberIds
        case inviteCode
        case createdAt
    }
}
