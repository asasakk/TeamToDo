import Foundation
import Combine
import FirebaseFirestore

@MainActor
class OrganizationManager: ObservableObject {
    @Published var organizations: [Organization] = []
    @Published var pendingInviteCode: String?
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
    
    func createOrganization(name: String, ownerId: String, password: String? = nil) async throws {
        let inviteCode = String(UUID().uuidString.prefix(6)).uppercased()
        
        let hashedPassword = password?.isEmpty == false ? password?.sha256Hash() : nil
        
        let organization = Organization(
            id: nil,
            name: name,
            ownerId: ownerId,
            memberIds: [ownerId],
            inviteCode: inviteCode,
            password: hashedPassword,
            createdAt: Date()
        )
        
        try db.collection("organizations").addDocument(from: organization)
    }
    
    // 招待コードから組織情報を取得（参加前の確認用）
    func getOrganizationByInviteCode(_ inviteCode: String) async throws -> Organization {
        let snapshot = try await db.collection("organizations")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw NSError(domain: "OrganizationManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "無効な招待コードです"])
        }
        
        return try document.data(as: Organization.self)
    }
    
    // パスワードの更新（空文字またはnilで削除）
    func updateOrganizationPassword(orgId: String, password: String?) async throws {
        let data: [String: Any]
        if let password = password, !password.isEmpty {
            data = ["password": password.sha256Hash()]
        } else {
            data = ["password": FieldValue.delete()]
        }
        try await db.collection("organizations").document(orgId).updateData(data)
    }
    
    func joinOrganization(inviteCode: String, userId: String) async throws {
        let snapshot = try await db.collection("organizations")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw NSError(domain: "OrganizationManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "無効な招待コードです"])
        }
        
        // Check if already a member
        if let organization = try? document.data(as: Organization.self),
            organization.memberIds.contains(userId) {
            throw NSError(domain: "OrganizationManager", code: 409, userInfo: [NSLocalizedDescriptionKey: "すでにこの組織に参加しています"])
        }
        
        try await document.reference.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
    }
    
    func leaveOrganization(orgId: String, userId: String) async throws {
        try await db.collection("organizations").document(orgId).updateData([
            "memberIds": FieldValue.arrayRemove([userId])
        ])
    }
}
