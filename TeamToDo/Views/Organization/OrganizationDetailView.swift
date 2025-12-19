import SwiftUI

struct OrganizationDetailView: View {
    let organization: Organization
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var orgManager: OrganizationManager
    @StateObject private var projectManager = ProjectManager()
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @State private var showCreateProject = false
    @State private var newProjectName = ""
    @State private var newProjectDescription = ""
    @State private var isArchivedExpanded = false
    @State private var showChangePassword = false
    @State private var newPasswordInput = ""
    @State private var showLeaveAlert = false
    @State private var showInviteQRCode = false
    
    var body: some View {
        List {
            if projectManager.projects.isEmpty {
                ContentUnavailableView("プロジェクトがありません", systemImage: "folder.badge.questionmark", description: Text("右上の＋ボタンからプロジェクトを作成してください"))
            } else {
                // 進行中のプロジェクト
                Section(header: Text("進行中")) {
                    ForEach(activeProjects) { project in
                        ProjectRowView(project: project)
                    }
                }
                
                // アーカイブ済みプロジェクト
                if !archivedProjects.isEmpty {
                    Section(header: 
                        HStack {
                            Text("アーカイブ済み (\(archivedProjects.count))")
                            Spacer()
                            Image(systemName: isArchivedExpanded ? "chevron.down" : "chevron.right")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                isArchivedExpanded.toggle()
                            }
                        }
                    ) {
                        if isArchivedExpanded {
                            ForEach(archivedProjects) { project in
                                ProjectRowView(project: project)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(organization.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateProject = true }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    NavigationLink(destination: OrganizationMemberListView(organization: organization)) {
                        Label("メンバー一覧", systemImage: "person.2")
                    }
                    
                    Button {
                        showInviteQRCode = true
                    } label: {
                        Label("メンバーを招待", systemImage: "person.badge.plus")
                    }
                    
                    Button {
                        // パスワードが設定されている場合は既存のものを表示しない（セキュリティ上）
                        newPasswordInput = "" 
                        showChangePassword = true
                    } label: {
                        if let pass = organization.password, !pass.isEmpty {
                            Label("パスワード変更/削除", systemImage: "lock.rotation")
                        } else {
                            Label("パスワード設定", systemImage: "lock")
                        }
                    }
                    
                    Divider()
                    
                    Button("組織から脱退", role: .destructive) {
                        showLeaveAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .alert("組織からの脱退", isPresented: $showLeaveAlert) {
                    Button("キャンセル", role: .cancel) { }
                    Button("脱退する", role: .destructive) {
                        leaveOrganization()
                    }
                } message: {
                    Text("本当にこの組織から脱退しますか？\n招待コードがあれば再参加可能です。")
                }
            }
        }
        
        // パスワード変更アラート
        .alert("パスワード設定", isPresented: $showChangePassword) {
            SecureField("新しいパスワード（空で削除）", text: $newPasswordInput)
            Button("更新") {
                updatePassword()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            if let pass = organization.password, !pass.isEmpty {
                Text("現在のパスワード設定：あり\n空欄にして更新するとパスワードを削除します。")
            } else {
                Text("現在のパスワード設定：なし\nパスワードを設定すると、参加時に入力が求められます。")
            }
        }
        
        .sheet(isPresented: $showInviteQRCode) {
            InviteQRCodeView(organizationName: organization.name, inviteCode: organization.inviteCode)
                .presentationDetents([.large])
        }
        .onAppear {
            if let id = organization.id {
                projectManager.fetchProjects(for: id)
            }
        }
        .sheet(isPresented: $showCreateProject) {
            NavigationStack {
                Form {
                    Section(header: Text("プロジェクト情報")) {
                        TextField("プロジェクト名", text: $newProjectName)
                        TextField("説明 (任意)", text: $newProjectDescription)
                    }
                }
                .navigationTitle("プロジェクト作成")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") { showCreateProject = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("作成") {
                            createProject()
                        }
                        .disabled(newProjectName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func updatePassword() {
        guard let orgId = organization.id else { return }
        Task {
            do {
                try await orgManager.updateOrganizationPassword(orgId: orgId, password: newPasswordInput.isEmpty ? nil : newPasswordInput)
            } catch {
                print("Error updating password: \(error)")
            }
        }
    }
    
    private func createProject() {
        guard let orgId = organization.id, let uid = firebaseManager.currentUser?.id else { return }
        
        Task {
            do {
                try await projectManager.createProject(
                    orgId: orgId,
                    name: newProjectName,
                    description: newProjectDescription.isEmpty ? nil : newProjectDescription,
                    memberIds: [uid] // Creator is a member
                )
                showCreateProject = false
                newProjectName = ""
                newProjectDescription = ""
            } catch {
                print("Error creating project: \(error)")
            }
        }
    }
    
    private func leaveOrganization() {
        guard let orgId = organization.id, let uid = firebaseManager.currentUser?.id else { return }
        
        Task {
            do {
                try await orgManager.leaveOrganization(orgId: orgId, userId: uid)
                dismiss() // Close the detail view
            } catch {
                print("Error leaving organization: \(error)")
            }
        }
    }
    
    private var activeProjects: [Project] {
        projectManager.projects.filter { !$0.isArchived }
    }
    
    private var archivedProjects: [Project] {
        projectManager.projects.filter { $0.isArchived }
    }
}
