import Foundation
import Combine
import FirebaseFirestore

@MainActor
class OrganizationManager: ObservableObject {
    @Published var organizations: [Organization] = []
    private let db = Firestore.firestore()
    
    func fetchOrganizations(for userId: String) {
        db.collection("organizations")
            .whereField("memberIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let documents = snapshot?.documents, error == nil else {
                        print("Error fetching organizations: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    self?.organizations = documents.compactMap { document in
                        try? document.data(as: Organization.self)
                    }
                }
            }
    }
    
    func createOrganization(name: String, ownerId: String) async throws {
        let inviteCode = String(UUID().uuidString.prefix(6)).uppercased()
        let organization = Organization(
            id: nil,
            name: name,
            ownerId: ownerId,
            memberIds: [ownerId],
            inviteCode: inviteCode,
            createdAt: Date()
        )
        
        try db.collection("organizations").addDocument(from: organization)
    }
    
    func joinOrganization(inviteCode: String, userId: String) async throws {
        let snapshot = try await db.collection("organizations")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw NSError(domain: "OrganizationManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid invite code"])
        }
        
        try await document.reference.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
    }
}
