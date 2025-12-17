import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var currentUser: User?
    @Published var isUserLoggedIn = false
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    init() {
        // ログイン状態を監視
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.isUserLoggedIn = true
                self?.fetchCurrentUser(uid: user.uid)
            } else {
                self?.isUserLoggedIn = false
                self?.currentUser = nil
            }
        }
    }
    
    // ユーザー情報を取得
    func fetchCurrentUser(uid: String) {
        let docRef = db.collection("users").document(uid)
        docRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                print("User document does not exist")
                return
            }
            
            do {
                self?.currentUser = try snapshot.data(as: User.self)
            } catch {
                print("Error decoding user: \(error)")
            }
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
