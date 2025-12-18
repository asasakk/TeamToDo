import SwiftUI

struct OrganizationDetailView: View {
    let organization: Organization
    @StateObject private var projectManager = ProjectManager()
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @State private var showCreateProject = false
    @State private var newProjectName = ""
    @State private var newProjectDescription = ""
    @State private var isArchivedExpanded = false
    
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
                    
                    Button("招待コードをコピー") {
                        UIPasteboard.general.string = organization.inviteCode
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
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
    
    private var activeProjects: [Project] {
        projectManager.projects.filter { !$0.isArchived }
    }
    
    private var archivedProjects: [Project] {
        projectManager.projects.filter { $0.isArchived }
    }
}
