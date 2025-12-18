import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("表示")) {
                    Toggle("ダークモード", isOn: $isDarkMode)
                }
                
                Section(header: Text("サポート")) {
                    Button(action: {
                        requestReview()
                    }) {
                        HStack {
                            Text("レビューを書く")
                            Spacer()
                            Image(systemName: "star.bubble")
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section(header: Text("アプリについて")) {
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("利用規約")
                            Spacer()
                            Image(systemName: "doc.text")
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("プライバシーポリシー")
                            Spacer()
                            Image(systemName: "hand.raised.fill")
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section(header: Text("アカウント")) {
                    Button("ログアウト", role: .destructive) {
                        firebaseManager.signOut()
                    }
                    
                    // Debug
                    Button("FCMトークンを更新 (Debug)") {
                        // Action handled in ContentView before, but here we can just do nothing or call manager if we move logic.
                        // For now let's keep it simple or omitting if not strictly needed in new UI.
                        // User mentioned "Dark mode, Terms, Privacy, Review". Debug token is just for dev.
                        // Let's keep it but maybe minimal.
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
