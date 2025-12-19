import SwiftUI

struct MyTasksView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var projectManager = ProjectManager() // Add ProjectManager
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var projectMap: [String: String] = [:] // projectId: projectName
    @State private var isCompletedExpanded = true
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            List {
                if !overdueTasks.isEmpty {
                    Section(header: Text("期限切れ").foregroundColor(.red)) {
                        ForEach(overdueTasks) { task in
                            TaskRow(task: task, projectName: projectMap[task.projectId ?? ""], memberColor: getMemberColor(for: task)) { toggleTaskStatus(task) }
                        }
                    }
                }
                
                if !todayTasks.isEmpty {
                    Section(header: Text("今日")) {
                        ForEach(todayTasks) { task in
                            TaskRow(task: task, projectName: projectMap[task.projectId ?? ""], memberColor: getMemberColor(for: task)) { toggleTaskStatus(task) }
                        }
                    }
                }
                
                if !upcomingTasks.isEmpty {
                    Section(header: Text("明日以降")) {
                        ForEach(upcomingTasks) { task in
                            TaskRow(task: task, projectName: projectMap[task.projectId ?? ""], memberColor: getMemberColor(for: task)) { toggleTaskStatus(task) }
                        }
                    }
                }
                
                if !noDateTasks.isEmpty {
                    Section(header: Text("期限なし")) {
                        ForEach(noDateTasks) { task in
                            TaskRow(task: task, projectName: projectMap[task.projectId ?? ""], memberColor: getMemberColor(for: task)) { toggleTaskStatus(task) }
                        }
                    }
                }
                
                if !completedTasks.isEmpty {
                    Section(header: 
                        Button(action: {
                            withAnimation { isCompletedExpanded.toggle() }
                        }) {
                            HStack {
                                Text("完了済み")
                                Spacer()
                                Image(systemName: isCompletedExpanded ? "chevron.down" : "chevron.right")
                            }
                        }
                        .foregroundColor(.secondary)
                    ) {
                        if isCompletedExpanded {
                            ForEach(completedTasks) { task in
                                TaskRow(task: task, projectName: projectMap[task.projectId ?? ""], memberColor: getMemberColor(for: task)) { toggleTaskStatus(task) }
                            }
                        }
                    }
                }
                
                if taskManager.tasks.isEmpty {
                    Text("割り当てられたタスクはありません")
                        .foregroundStyle(.gray)
                        .padding()
                }
            }
            .listStyle(.plain)
            .navigationTitle("ホーム (自分のタスク)")
            .onAppear {
                if let uid = firebaseManager.currentUser?.id {
                    taskManager.fetchAssignedTasks(for: uid)
                }
            }
            .onChange(of: taskManager.tasks) { newTasks in // iOS 17+ syntax? For compatibility using newTasks
                Task {
                   await loadProjectNames(for: newTasks)
                }
            }
            .onChange(of: firebaseManager.currentUser) { newUser in
                if let uid = newUser?.id {
                    taskManager.fetchAssignedTasks(for: uid)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    // Helper for color
    private func getMemberColor(for task: AppTask) -> Color {
        return Color.memberColor(userId: task.assignedTo)
    }
    
    private var sortedTasks: [AppTask] {
        taskManager.tasks.sorted {
            if $0.priority != $1.priority {
               // High should come first. CaseIterable order is High, Medium, Low.
               // We want High < Medium < Low index?
               // Actually we defined High, Medium, Low.
               // Let's rely on explicit mapping or index.
               let p1 = priorityValue($0.priority)
               let p2 = priorityValue($1.priority)
               return p1 > p2
            }
            return $0.createdAt > $1.createdAt
        }
    }

    private func priorityValue(_ p: TaskPriority) -> Int {
        switch p {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }

    private var overdueTasks: [AppTask] {
        sortedTasks.filter { !$0.isCompleted && isOverdue($0) }
    }
    
    private var todayTasks: [AppTask] {
        sortedTasks.filter { !$0.isCompleted && isToday($0) }
    }
    
    private var upcomingTasks: [AppTask] {
        sortedTasks.filter { !$0.isCompleted && isUpcoming($0) }
    }
    
    private var noDateTasks: [AppTask] {
        sortedTasks.filter { !$0.isCompleted && $0.dueDate == nil }
    }
    
    private var completedTasks: [AppTask] {
        sortedTasks.filter { $0.isCompleted }
    }
    
    private func isOverdue(_ task: AppTask) -> Bool {
        guard let date = task.dueDate else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }
    
    private func isToday(_ task: AppTask) -> Bool {
        guard let date = task.dueDate else { return false }
        return Calendar.current.isDateInToday(date)
    }
    
    private func isUpcoming(_ task: AppTask) -> Bool {
        guard let date = task.dueDate else { return false }
        return date >= Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
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
    
    private func loadProjectNames(for tasks: [AppTask]) async {
        let projectIds = Set(tasks.compactMap { $0.projectId }).filter { projectMap[$0] == nil } // Only fetch missing
        guard !projectIds.isEmpty else { return }
        
        let projects = await projectManager.fetchProjects(ids: Array(projectIds))
        for project in projects {
            if let id = project.id {
                projectMap[id] = project.name
            }
        }
    }
}
