import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var fcmToken: String?
    var createdAt: Date?
    
    // CodingKeys removed to allow @DocumentID to work correctly and to match other models.
}
