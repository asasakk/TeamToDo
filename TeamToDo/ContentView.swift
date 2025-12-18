import SwiftUI

struct ContentView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var orgManager = OrganizationManager()
    
    var body: some View {
        Group {
            if firebaseManager.isUserLoggedIn {
                TabView {
                    MyTasksView()
                        .tabItem {
                            Label("ホーム", systemImage: "house.fill")
                        }
                    
                    OrganizationListView()
                        .tabItem {
                            Label("チーム", systemImage: "person.3.fill")
                        }
                    
                    VStack {
                        Button("ログアウト") {
                            firebaseManager.signOut()
                        }
                        .padding()
                        
                        Divider()
                        
                        Button("FCMトークンを更新 (Debug)") {
                            Task {
                                if let token = try? await Messaging.messaging().token() {
                                    if let uid = firebaseManager.currentUser?.id {
                                        await firebaseManager.updateFCMToken(token, uid: uid)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .tabItem {
                        Label("設定", systemImage: "gearshape.fill")
                    }
                }
                .environmentObject(orgManager)
                .onAppear {
                    if let uid = firebaseManager.currentUser?.id {
                        orgManager.startListening(for: uid)
                    }
                }
                .onChange(of: firebaseManager.currentUser) { _, newUser in
                    if let uid = newUser?.id {
                        orgManager.startListening(for: uid)
                    } else {
                        orgManager.stopListening()
                    }
                }
                .onDisappear {
                    orgManager.stopListening()
                }

            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: firebaseManager.isUserLoggedIn)
    }
}
