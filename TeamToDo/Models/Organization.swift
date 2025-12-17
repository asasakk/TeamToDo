import Foundation
import FirebaseFirestore

struct Organization: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var memberIds: [String]
    var inviteCode: String
    var createdAt: Date
    
    // CodingKeys removed to allow @DocumentID to work correctly.
    // Properties match Firestore field names automatically.
}
