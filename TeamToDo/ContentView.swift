import SwiftUI

struct ContentView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    var body: some View {
        Group {
            if firebaseManager.isUserLoggedIn {
                OrganizationListView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: firebaseManager.isUserLoggedIn)
    }
}
