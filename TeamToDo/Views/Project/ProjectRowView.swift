import SwiftUI

struct ProjectRowView: View {
    let project: Project
    @StateObject private var taskManager = TaskManager()
    @StateObject private var projectManager = ProjectManager() // アーカイブ操作用
    @State private var progress: (total: Int, completed: Int) = (0, 0)
    @State private var isLoading = true
    
    var body: some View {
        NavigationLink(destination: TaskListView(project: project)) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                        .strikethrough(project.isArchived)
                    
                    if project.isArchived {
                        Text("アーカイブ済み")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                if let description = project.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
                
                if !project.isArchived {
                    // 進捗バー
                    HStack {
                        ProgressView(value: Double(progress.completed), total: Double(max(progress.total, 1)))
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .contextMenu {
            if project.isArchived {
                Button(action: {
                    Task { try? await projectManager.unarchiveProject(project) }
                }) {
                    Label("アーカイブ解除", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button(action: {
                    Task { try? await projectManager.archiveProject(project) }
                }) {
                    Label("アーカイブ", systemImage: "archivebox")
                }
            }
        }
        .onAppear {
            fetchProgress()
        }
    }
    
    private var progressPercentage: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.completed) / Double(progress.total)
    }
    
    private func fetchProgress() {
        guard let projectId = project.id else { return }
        Task {
            progress = await taskManager.fetchProjectProgress(projectId: projectId)
            isLoading = false
        }
    }
}
