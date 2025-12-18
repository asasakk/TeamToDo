import SwiftUI

extension Color {
    // Simplified color logic based on user request: Self = Cyan, Others = Pink
    static func memberColor(userId: String?) -> Color {
        guard let userId = userId else { return .gray }
        
        if let currentUid = FirebaseManager.shared.currentUser?.id, currentUid == userId {
            return .cyan
        } else {
            return .pink
        }
    }
}
