import SwiftUI

struct OrganizationMemberListView: View {
    let organization: Organization
    @StateObject private var orgManager = OrganizationManager()
    @State private var members: [AppUser] = []
    
    var body: some View {
        List {
            ForEach(members) { member in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                        Text(member.displayName)
                            .font(.headline)
                        Text(member.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if member.id == organization.ownerId {
                        Text("オーナー")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("メンバー")
        .onAppear {
            Task {
                members = await orgManager.fetchMembers(for: organization)
            }
        }
    }
}
