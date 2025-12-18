import Foundation
import Combine
import FirebaseFirestore

@MainActor
class OrganizationManager: ObservableObject {
    @Published var organizations: [Organization] = []
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func startListening(for userId: String) {
        // Prevent multiple listeners
        if listenerRegistration != nil { return }
        
        print("DEBUG: Included in startListening for user: \(userId)")
        
        listenerRegistration = db.collection("organizations")
            .whereField("memberIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching organizations: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("Error: Snapshot is nil")
                    return
                }
                
                Task { @MainActor in
                    let newOrganizations = snapshot.documents.compactMap { document -> Organization? in
                        try? document.data(as: Organization.self)
                    }
                    
                    self.organizations = newOrganizations
                }
            }
    }
    
    func stopListening() {
        print("DEBUG: stopListening called")
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    func fetchMembers(for organization: Organization) async -> [AppUser] {
        return await FirebaseManager.shared.fetchUsers(uids: organization.memberIds)
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
