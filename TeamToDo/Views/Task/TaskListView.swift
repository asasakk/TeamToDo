import SwiftUI

struct TaskListView: View {
    let project: Project
    @StateObject private var taskManager = TaskManager()
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var projectMembers: [AppUser] = []
    @State private var showCreateTask = false
    @State private var showMemberSelection = false
    
    // New Task Inputs
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var newTaskDueDate: Date = Date()
    @State private var hasDueDate = false
    @State private var selectedAssigneeId: String?
    
    var sortedTasks: [AppTask] {
        taskManager.tasks.sorted { t1, t2 in
            // Uncompleted first, then by date desc
            if t1.isCompleted != t2.isCompleted {
                return !t1.isCompleted
            }
            return t1.createdAt > t2.createdAt
        }
    }
    
    var body: some View {
        List {
            ForEach(sortedTasks) { task in
                TaskRow(task: task, members: projectMembers) {
                    toggleTaskStatus(task)
                }
            }
        }
        .navigationTitle(project.name)
        .toolbar {
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
                                if let selectedId = selectedAssigneeId, 
                                   let member = projectMembers.first(where: { $0.id == selectedId }) {
                                    Text(member.displayName)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("未割り当て")
                                        .foregroundColor(.gray)
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
                    MemberSelectionView(members: projectMembers, selectedAssigneeId: $selectedAssigneeId)
                }
            }
        }
    }
    
    private func loadMembers() {
        Task {
            projectMembers = await firebaseManager.fetchUsers(uids: project.memberIds)
        }
    }
    
    private func toggleTaskStatus(_ task: AppTask) {
        guard let projectId = project.id, let taskId = task.id else { return }
        Task {
            try? await taskManager.updateTaskstatus(projectId: projectId, taskId: taskId, isCompleted: !task.isCompleted)
            if task.isCompleted {
                // Was completed, now uncompleted -> check if we need to schedule
                // But we don't have the full task with updated status here easily unless we fetch or assume.
                // Simplification for now.
            } else {
                // Was uncompleted, now completed -> remove notification
                NotificationManager.shared.removeNotification(for: taskId)
            }
        }
    }
    
    private func createTask() {
        guard let projectId = project.id, let currentUid = firebaseManager.currentUser?.id else { return }
        Task {
            do {
                let taskId = try await taskManager.createTask(
                    projectId: projectId,
                    title: newTaskTitle,
                    description: newTaskDescription.isEmpty ? nil : newTaskDescription,
                    dueDate: hasDueDate ? newTaskDueDate : nil,
                    assignedTo: selectedAssigneeId,
                    createdBy: currentUid
                )
                
                // If assigned to current user (or if we want to notify self when assigning to self), schedule notification
                if let assignedTo = selectedAssigneeId, assignedTo == currentUid, hasDueDate {
                    let taskForNotification = AppTask(
                        id: taskId,
                        title: newTaskTitle,
                        description: newTaskDescription,
                        dueDate: newTaskDueDate,
                        isCompleted: false,
                        assignedTo: assignedTo,
                        createdBy: currentUid,
                        createdAt: Date()
                    )
                    NotificationManager.shared.scheduleNotification(for: taskForNotification)
                }
                
                // Reset fields
                newTaskTitle = ""
                newTaskDescription = ""
                hasDueDate = false
                selectedAssigneeId = nil
                
            } catch {
                print("Error creating task: \(error)")
            }
        }
    }
}

struct TaskRow: View {
    let task: AppTask
    let members: [AppUser]
    let onToggle: () -> Void
    
    var assignedUser: AppUser? {
        guard let assignedTo = task.assignedTo else { return nil }
        return members.first { $0.id == assignedTo }
    }
    
    var isOverdue: Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }
                
                HStack {
                    if let assignedUser = assignedUser {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                            Text(assignedUser.displayName)
                        }
                        .font(.caption2)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(dueDate, style: .date)
                            Text(dueDate, style: .time)
                        }
                        .font(.caption2)
                        .padding(4)
                        .background(isOverdue ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                        .foregroundColor(isOverdue ? .red : .primary)
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
