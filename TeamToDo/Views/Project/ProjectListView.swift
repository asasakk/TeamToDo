import SwiftUI

struct ProjectListView: View {
    let organization: Organization
    @StateObject private var projectManager = ProjectManager()
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @State private var showCreateProject = false
    @State private var newProjectName = ""
    @State private var newProjectDescription = ""
    
    var body: some View {
        List(projectManager.projects) { project in
            NavigationLink(destination: TaskListView(project: project)) {
                VStack(alignment: .leading) {
                    Text(project.name)
                        .font(.headline)
                    if let description = project.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .navigationTitle(organization.name) // Use organization name as title
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateProject = true }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Organization settings/invite code could go here
                    ShareLink(item: organization.inviteCode, preview: SharePreview("招待コード: \(organization.inviteCode)")) {
                        Text("招待コードを共有")
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text("招待コード: \(organization.inviteCode)")
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            if let orgId = organization.id {
                projectManager.fetchProjects(for: orgId)
            }
        }
        .alert("プロジェクトを作成", isPresented: $showCreateProject) {
            TextField("プロジェクト名", text: $newProjectName)
            TextField("説明 (任意)", text: $newProjectDescription)
            Button("作成") {
                Task {
                    if let orgId = organization.id {
                        try? await projectManager.createProject(
                            orgId: orgId,
                            name: newProjectName,
                            description: newProjectDescription.isEmpty ? nil : newProjectDescription,
                            memberIds: organization.memberIds // Initially all org members? Or copy? For now all org members.
                        )
                        newProjectName = ""
                        newProjectDescription = ""
                    }
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
    }
}
