import SwiftUI

struct TaskListView: View {
    let project: Project
    @StateObject private var taskManager = TaskManager()
    @StateObject private var projectManager = ProjectManager() // Add ProjectManager
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var projectMembers: [AppUser] = []
    @State private var showCreateTask = false
    @State private var showMemberSelection = false
    @State private var showJoinProjectAlert = false // Add Join Alert State
    
    // New Task Inputs
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var newTaskDueDate: Date = Date()
    @State private var hasDueDate = false
    @State private var selectedAssigneeIds: Set<String> = []
    
    @State private var selectedTask: AppTask? // Add selectedTask state
    @State private var selectedFilterUserId: String? // nil = shows nothing or all? User requested "Default: Self, Select: Others". So init with currentUser.
    
    var filteredTasks: [AppTask] {
        guard let filterId = selectedFilterUserId else { return [] }
        return taskManager.tasks.filter { $0.assignedTo == filterId }
    }
    
    var incompleteTasks: [AppTask] {
        filteredTasks.filter { !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var completedTasks: [AppTask] {
        filteredTasks.filter { $0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        List {
            if !incompleteTasks.isEmpty {
                Section(header: Text("未完了のタスク")) {
                    ForEach(incompleteTasks) { task in
                        TaskRow(task: task, members: projectMembers) {
                            toggleTaskStatus(task)
                        }
                        .contentShape(Rectangle()) // Make the whole row tappable
                        .onTapGesture {
                            selectedTask = task
                        }
                    }
                }
            }
            
            if !completedTasks.isEmpty {
                Section(header: Text("完了済みのタスク")) {
                   ForEach(completedTasks) { task in
                       TaskRow(task: task, members: projectMembers) {
                           toggleTaskStatus(task)
                       }
                       .contentShape(Rectangle())
                       .onTapGesture {
                           selectedTask = task
                       }
                   }
                }
            }
            
            if incompleteTasks.isEmpty && completedTasks.isEmpty {
                Text("タスクがありません")
                    .foregroundStyle(.gray)
                    .padding()
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Text("表示するメンバー")
                    Divider()
                    ForEach(projectMembers) { member in
                        Button {
                            selectedFilterUserId = member.id
                        } label: {
                            HStack {
                                Text(member.displayName)
                                if selectedFilterUserId == member.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateTask = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            if let projectId = project.id {
                taskManager.fetchTasks(for: projectId)
            }
            loadMembers()
            NotificationManager.shared.requestAuthorization()
        }
        .sheet(item: $selectedTask) { task in
            TaskEditView(task: task, projectMembers: projectMembers, taskManager: taskManager)
        }
        .sheet(isPresented: $showCreateTask) {
            NavigationStack {
                Form {
                    Section(header: Text("タスク内容")) {
                        TextField("タイトル", text: $newTaskTitle)
                        TextField("詳細 (任意)", text: $newTaskDescription)
                    }
                    
                    Section(header: Text("担当者")) {
                        Button {
                            showMemberSelection = true
                        } label: {
                            HStack {
                                Text("担当者")
                                Spacer()
                                if selectedAssigneeIds.isEmpty {
                                    Text("未割り当て")
                                        .foregroundColor(.gray)
                                } else {
                                    Text("\(selectedAssigneeIds.count)名選択中")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("期限")) {
                        Toggle("期限を設定", isOn: $hasDueDate)
                        if hasDueDate {
                            DatePicker("期限", selection: $newTaskDueDate, displayedComponents: [.date, .hourAndMinute])
                        }
                    }
                }
                .navigationTitle("タスク作成")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") { showCreateTask = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("作成") {
                            createTask()
                            showCreateTask = false
                        }
                        .disabled(newTaskTitle.isEmpty)
                    }
                }
                .sheet(isPresented: $showMemberSelection) {
                    MemberSelectionView(members: projectMembers, selectedAssigneeIds: $selectedAssigneeIds)
                }
            }
        }
        .alert("プロジェクトに参加", isPresented: $showJoinProjectAlert) {
            Button("参加する") {
                joinProject()
            }
            Button("キャンセル", role: .cancel) {
                // Optionally pop back? For now just dismiss alert.
            }
        } message: {
            Text("このプロジェクトに参加してタスクを管理しますか？")
        }
    }
    
    private func loadMembers() {
        Task {
            projectMembers = await firebaseManager.fetchUsers(uids: project.memberIds)
            // Default select current user if not set
            if selectedFilterUserId == nil {
                selectedFilterUserId = firebaseManager.currentUser?.id
            }
            
            // Check if current user is a member
            if let currentUid = firebaseManager.currentUser?.id {
                if !project.memberIds.contains(currentUid) {
                    showJoinProjectAlert = true
                }
            }
        }
    }
    
    private func joinProject() {
        guard let projectId = project.id, let currentUid = firebaseManager.currentUser?.id else { return }
        Task {
            try? await projectManager.joinProject(projectId: projectId, userId: currentUid)
            if let currentUser = firebaseManager.currentUser {
                projectMembers.append(currentUser)
            }
        }
    }
    
    private func toggleTaskStatus(_ task: AppTask) {
        guard let projectId = project.id, let taskId = task.id else { return }
        Task {
            try? await taskManager.updateTaskstatus(projectId: projectId, taskId: taskId, isCompleted: !task.isCompleted)
            if task.isCompleted {
                // Was completed, now uncompleted
            } else {
                // Was uncompleted, now completed
                NotificationManager.shared.removeNotification(for: taskId)
            }
        }
    }
    
    private func createTask() {
        guard let projectId = project.id, let currentUid = firebaseManager.currentUser?.id else { return }
        Task {
            do {
                if selectedAssigneeIds.isEmpty {
                    // Create single unassigned task
                     _ = try await taskManager.createTask(
                        projectId: projectId,
                        title: newTaskTitle,
                        description: newTaskDescription.isEmpty ? nil : newTaskDescription,
                        dueDate: hasDueDate ? newTaskDueDate : nil,
                        assignedTo: nil,
                        createdBy: currentUid
                    )
                } else {
                    // Create task for each assignee
                    for assigneeId in selectedAssigneeIds {
                        let taskId = try await taskManager.createTask(
                            projectId: projectId,
                            title: newTaskTitle,
                            description: newTaskDescription.isEmpty ? nil : newTaskDescription,
                            dueDate: hasDueDate ? newTaskDueDate : nil,
                            assignedTo: assigneeId,
                            createdBy: currentUid
                        )
                        
                        // If assigned to self, schedule notification
                        if assigneeId == currentUid, hasDueDate {
                            let taskForNotification = AppTask(
                                id: taskId,
                                title: newTaskTitle,
                                description: newTaskDescription,
                                dueDate: newTaskDueDate,
                                isCompleted: false,
                                assignedTo: assigneeId,
                                createdBy: currentUid,
                                createdAt: Date()
                            )
                            NotificationManager.shared.scheduleNotification(for: taskForNotification)
                        }
                    }
                }
                
                // Reset fields
                newTaskTitle = ""
                newTaskDescription = ""
                hasDueDate = false
                selectedAssigneeIds = []
                
            } catch {
                print("Error creating task: \(error)")
            }
        }
    }
}


