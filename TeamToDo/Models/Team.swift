import Foundation
import FirebaseFirestore

struct Team: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var memberIds: [String]
    var inviteCode: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ownerId
        case memberIds
        case inviteCode
    }
}
