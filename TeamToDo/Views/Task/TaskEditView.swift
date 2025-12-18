import SwiftUI

struct TaskEditView: View {
    @Environment(\.dismiss) var dismiss
    let task: AppTask
    let projectMembers: [AppUser]
    @ObservedObject var taskManager: TaskManager
    
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var selectedAssigneeIds: Set<String> = []
    
    @State private var showMemberSelection = false
    
    init(task: AppTask, projectMembers: [AppUser], taskManager: TaskManager) {
        self.task = task
        self.projectMembers = projectMembers
        self.taskManager = taskManager
        
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        if let date = task.dueDate {
            _dueDate = State(initialValue: date)
            _hasDueDate = State(initialValue: true)
        } else {
            _dueDate = State(initialValue: Date())
            _hasDueDate = State(initialValue: false)
        }
        
        if let assigneeId = task.assignedTo {
            _selectedAssigneeIds = State(initialValue: [assigneeId])
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("タスク内容")) {
                    TextField("タイトル", text: $title)
                    TextField("詳細 (任意)", text: $description)
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
                                // For MVP we support single assignee for edit
                                // But the selection view supports multiple.
                                // Logic below will take the first one.
                                if let firstId = selectedAssigneeIds.first,
                                   let member = projectMembers.first(where: { $0.id == firstId }) {
                                    Text(member.displayName)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("選択中")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("期限")) {
                    Toggle("期限を設定", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("期限", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section {
                    Button("タスクを削除", role: .destructive) {
                        deleteTask()
                    }
                }
            }
            .navigationTitle("タスク編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showMemberSelection) {
                MemberSelectionView(members: projectMembers, selectedAssigneeIds: $selectedAssigneeIds)
            }
        }
    }
    
    private func saveTask() {
        guard let projectId = task.projectId, let taskId = task.id else { return }
        
        Task {
            do {
                try await taskManager.updateTask(
                    projectId: projectId,
                    taskId: taskId,
                    title: title,
                    description: description.isEmpty ? nil : description,
                    dueDate: hasDueDate ? dueDate : nil,
                    assignedTo: selectedAssigneeIds.first
                )
                dismiss()
            } catch {
                print("Error updating task: \(error)")
            }
        }
    }
    
    private func deleteTask() {
        guard let projectId = task.projectId, let taskId = task.id else { return }
        
        Task {
            do {
                try await taskManager.deleteTask(projectId: projectId, taskId: taskId)
                dismiss()
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }
}
