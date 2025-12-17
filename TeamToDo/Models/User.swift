import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    
    // Firestoreで使用するキー
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
    }
}
