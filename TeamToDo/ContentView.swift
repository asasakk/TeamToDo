import SwiftUI
import FirebaseMessaging

struct ContentView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @EnvironmentObject var orgManager: OrganizationManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if firebaseManager.isUserLoggedIn {
                VStack(spacing: 0) {
                    TabView(selection: $selectedTab) {
                        MyTasksView()
                            .tabItem {
                                Label("ホーム", systemImage: "house.fill")
                            }
                            .tag(0)
                        
                        OrganizationListView()
                            .tabItem {
                                Label("チーム", systemImage: "person.3.fill")
                            }
                            .tag(1)
                        
                        CalendarView()
                            .tabItem {
                                Label("カレンダー", systemImage: "calendar")
                            }
                            .tag(2)
                    }
                    
                    // AdMob Banner
                    AdMobBannerView(adUnitID: "ca-app-pub-3940256099942544/2934735716") // Test ID
                        .frame(height: 50)
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    if let uid = firebaseManager.currentUser?.id {
                        orgManager.startListening(for: uid)
                    }
                }
                .onChange(of: orgManager.pendingInviteCode) { code in
                    if code != nil {
                        selectedTab = 1 // Switch to Organization Tab
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
