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
                    
                    Button("ログアウト") {
                        firebaseManager.signOut()
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
