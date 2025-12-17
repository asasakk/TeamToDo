import SwiftUI

struct OrganizationListView: View {
    @StateObject private var orgManager = OrganizationManager()
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showCreateOrg = false
    @State private var showJoinOrg = false
    @State private var newOrgName = ""
    @State private var inviteCodeInput = ""
    
    var body: some View {
        NavigationStack {
            List(orgManager.organizations) { org in
                NavigationLink(destination: ProjectListView(organization: org)) {
                    VStack(alignment: .leading) {
                        Text(org.name)
                            .font(.headline)
                        Text("メンバー: \(org.memberIds.count)名")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("組織選択")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("組織を作成") { showCreateOrg = true }
                        Button("組織に参加") { showJoinOrg = true }
                        Button("ログアウト", role: .destructive) {
                            firebaseManager.signOut()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                if let uid = firebaseManager.currentUser?.id {
                    orgManager.fetchOrganizations(for: uid)
                }
            }
            .alert("組織を作成", isPresented: $showCreateOrg) {
                TextField("組織名", text: $newOrgName)
                Button("作成") {
                    Task {
                        // TODO: Handle error properly
                        if let uid = firebaseManager.currentUser?.id {
                            try? await orgManager.createOrganization(name: newOrgName, ownerId: uid)
                            newOrgName = ""
                        }
                    }
                }
                Button("キャンセル", role: .cancel) { }
            }
            .alert("組織に参加", isPresented: $showJoinOrg) {
                TextField("招待コード", text: $inviteCodeInput)
                Button("参加") {
                    Task {
                        if let uid = firebaseManager.currentUser?.id {
                            try? await orgManager.joinOrganization(inviteCode: inviteCodeInput, userId: uid)
                            inviteCodeInput = ""
                        }
                    }
                }
                Button("キャンセル", role: .cancel) { }
            }
        }
    }
}
