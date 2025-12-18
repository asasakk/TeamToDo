import SwiftUI
import FirebaseMessaging

struct ContentView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var orgManager = OrganizationManager()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        Group {
            if firebaseManager.isUserLoggedIn {
                VStack(spacing: 0) {
                    TabView {
                        MyTasksView()
                            .tabItem {
                                Label("ホーム", systemImage: "house.fill")
                            }
                        
                        OrganizationListView()
                            .tabItem {
                                Label("チーム", systemImage: "person.3.fill")
                            }
                        
                        CalendarView()
                            .tabItem {
                                Label("カレンダー", systemImage: "calendar")
                            }
                    }
                    
                    // AdMob Banner
                    AdMobBannerView(adUnitID: "ca-app-pub-3940256099942544/2934735716") // Test ID
                        .frame(height: 50)
                }
                .environmentObject(orgManager)
                .preferredColorScheme(isDarkMode ? .dark : .light)
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
