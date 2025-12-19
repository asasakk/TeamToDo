import SwiftUI

struct OrganizationListView: View {
    @EnvironmentObject var orgManager: OrganizationManager
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @State private var showCreateOrg = false
    @State private var showJoinOrg = false
    @State private var showPasswordInput = false // パスワード入力アラート表示用
    
    @State private var newOrgName = ""
    @State private var newOrgPassword = "" // 新規作成時のパスワード
    
    @State private var inviteCodeInput = ""
    @State private var inputPassword = "" // 参加時のパスワード入力
    @State private var tempOrganization: Organization? // パスワードチェック待ちの組織
    
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if orgManager.organizations.isEmpty {
                    ContentUnavailableView("所属している組織がありません", systemImage: "person.slash", description: Text("右上の＋ボタンから組織を作成または参加してください"))
                } else {
                    List {
                        ForEach(orgManager.organizations) { org in
                            NavigationLink(destination: OrganizationDetailView(organization: org)) {
                                VStack(alignment: .leading) {
                                    Text(org.name)
                                        .font(.headline)
                                    Text("メンバー: \(org.memberIds.count)名")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("組織選択")
            .onAppear {
                checkPendingInvite()
            }
            .onChange(of: orgManager.pendingInviteCode) { _ in
                checkPendingInvite()
            }
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("再接続") {
                        if let uid = firebaseManager.currentUser?.id {
                            orgManager.stopListening()
                            orgManager.startListening(for: uid)
                        }
                    }
                }
            }
            
            // 組織作成アラート
            .alert("組織を作成", isPresented: $showCreateOrg) {
                TextField("組織名", text: $newOrgName)
                TextField("パスワード（任意）", text: $newOrgPassword)
                Button("作成") {
                    Task {
                        if let uid = firebaseManager.currentUser?.id {
                            let pass = newOrgPassword.isEmpty ? nil : newOrgPassword
                            try? await orgManager.createOrganization(name: newOrgName, ownerId: uid, password: pass)
                            newOrgName = ""
                            newOrgPassword = ""
                        }
                    }
                }
                Button("キャンセル", role: .cancel) {
                    newOrgName = ""
                    newOrgPassword = ""
                }
            }
            
            // 組織参加アラート（コード入力）
            .alert("組織に参加", isPresented: $showJoinOrg) {
                TextField("招待コード", text: $inviteCodeInput)
                Button("次へ") {
                    Task {
                        do {
                            // まず組織情報を取得して確認
                            let org = try await orgManager.getOrganizationByInviteCode(inviteCodeInput)
                            
                            // パスワードがあるかチェック
                            if let password = org.password, !password.isEmpty {
                                tempOrganization = org
                                showPasswordInput = true
                            } else {
                                // パスワードがない場合はそのまま参加
                                if let uid = firebaseManager.currentUser?.id {
                                    try await orgManager.joinOrganization(inviteCode: inviteCodeInput, userId: uid)
                                    inviteCodeInput = ""
                                }
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            showErrorAlert = true
                        }
                    }
                }
                Button("キャンセル", role: .cancel) {
                    orgManager.pendingInviteCode = nil
                }
            }
            
            // パスワード入力アラート
            .alert("パスワードを入力", isPresented: $showPasswordInput) {
                SecureField("パスワード", text: $inputPassword)
                Button("参加") {
                    Task {
                        // パスワード照合
                        if let org = tempOrganization, org.password == inputPassword {
                            if let uid = firebaseManager.currentUser?.id {
                                do {
                                    try await orgManager.joinOrganization(inviteCode: inviteCodeInput, userId: uid)
                                    inviteCodeInput = ""
                                    inputPassword = ""
                                    tempOrganization = nil
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showErrorAlert = true
                                }
                            }
                        } else {
                            errorMessage = "パスワードが間違っています"
                            showErrorAlert = true
                        }
                    }
                }
                Button("キャンセル", role: .cancel) {
                    inputPassword = ""
                    tempOrganization = nil
                    orgManager.pendingInviteCode = nil 
                }
            }
            
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func checkPendingInvite() {
        if let code = orgManager.pendingInviteCode {
            // 少し遅延させないとAlertが表示されないことがあるため
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                inviteCodeInput = code
                showJoinOrg = true
            }
        }
    }
}
