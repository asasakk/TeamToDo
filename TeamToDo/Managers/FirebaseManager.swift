import Foundation
import SwiftUI
import Combine
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseMessaging
@preconcurrency import FirebaseFirestore

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var currentUser: AppUser?
    @Published var isUserLoggedIn = false
    
    private let db = Firestore.firestore()
    let auth = Auth.auth()
    
    init() {
        // ログイン状態を監視
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            let uid = user?.uid // Extract String which is Sendable
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let uid = uid {
                    self.isUserLoggedIn = true
                    self.fetchCurrentUser(uid: uid)
                    
                    // ログイン時にFCMトークンを更新
                    Messaging.messaging().token { token, error in
                        if let error = error {
                            print("Error fetching FCM token: \(error)")
                        } else if let token = token {
                            Task {
                                await self.updateFCMToken(token, uid: uid)
                            }
                        }
                    }
                } else {
                    self.isUserLoggedIn = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    // ユーザー情報を取得
    func fetchCurrentUser(uid: String) {
        let docRef = db.collection("users").document(uid)
        docRef.getDocument { [weak self] snapshot, error in
            Task { @MainActor [weak self] in
                if let error = error {
                    print("Error fetching user: \(error)")
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    print("User document does not exist")
                    return
                }
                
                do {
                    self?.currentUser = try snapshot.data(as: AppUser.self)
                } catch {
                    print("Error decoding user: \(error)")
                }
            }
        }
    }
    
    // uidを引数として受け取るように変更
    func updateFCMToken(_ token: String, uid: String) async {
        print("Attempting to update FCM token for user: \(uid)")
        do {
            try await db.collection("users").document(uid).updateData([
                "fcmToken": token
            ])
            print("FCM Token updated successfully for \(uid)")
        } catch {
            print("Error updating FCM token: \(error)")
        }
    }
    
    // 複数のユーザー情報を取得
    func fetchUsers(uids: [String]) async -> [AppUser] {
        guard !uids.isEmpty else { return [] }
        
        // Firestore 'in' query supports up to 10 items.
        // For production, we need to batch this. For now, we'll loop or use chunks if needed.
        // Assuming small team size for MVP.
        
        do {
            // chunk into 10s
            var users: [AppUser] = []
            let chunks = stride(from: 0, to: uids.count, by: 10).map {
                Array(uids[$0..<min($0 + 10, uids.count)])
            }
            
            for chunk in chunks {
                let snapshot = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                
                let chunkUsers = snapshot.documents.compactMap { try? $0.data(as: AppUser.self) }
                users.append(contentsOf: chunkUsers)
            }
            
            return users
        } catch {
            print("Error fetching users: \(error)")
            return []
        }
    }

    // ログアウト
    func signOut() {
        do {
            try auth.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
