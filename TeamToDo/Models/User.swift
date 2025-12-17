import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var fcmToken: String?
    var createdAt: Date?
    
    // Firestoreで使用するキー
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case fcmToken
        case createdAt
    }
}
