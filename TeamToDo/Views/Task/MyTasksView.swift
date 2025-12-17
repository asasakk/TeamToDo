import SwiftUI

struct MyTasksView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                if !incompleteTasks.isEmpty {
                    Section(header: Text("未完了のタスク")) {
                        ForEach(incompleteTasks) { task in
                            TaskRow(task: task) {
                                toggleTaskStatus(task)
                            }
                        }
                    }
                }
                
                if !completedTasks.isEmpty {
                    Section(header: Text("完了済みのタスク")) {
                        ForEach(completedTasks) { task in
                            TaskRow(task: task) {
                                toggleTaskStatus(task)
                            }
                        }
                    }
                }
                
                if incompleteTasks.isEmpty && completedTasks.isEmpty {
                    Text("割り当てられたタスクはありません")
                        .foregroundStyle(.gray)
                        .padding()
                }
            }
            .navigationTitle("ホーム (自分のタスク)")
            .onAppear {
                if let uid = firebaseManager.currentUser?.id {
                    taskManager.fetchAssignedTasks(for: uid)
                }
            }
        }
    }
    
    private var incompleteTasks: [AppTask] {
        taskManager.tasks.filter { !$0.isCompleted }
    }
    
    private var completedTasks: [AppTask] {
        taskManager.tasks.filter { $0.isCompleted }
    }
    
    private func toggleTaskStatus(_ task: AppTask) {
        // Need projectId to update
        guard let projectId = task.projectId, let taskId = task.id else {
            print("Cannot update task without projectId")
            return
        }
        
        Task {
            try? await taskManager.updateTaskstatus(projectId: projectId, taskId: taskId, isCompleted: !task.isCompleted)
            // No notification needed for self-toggle usually, but could add if managed by someone else
        }
    }
}
