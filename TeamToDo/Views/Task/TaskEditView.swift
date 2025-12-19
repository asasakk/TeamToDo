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
    @State private var priority: TaskPriority
    @State private var selectedAssigneeIds: Set<String> = []
    @State private var subtasks: [SubTask]
    @State private var newSubtaskTitle: String = ""
    
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
            let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()
            _dueDate = State(initialValue: endOfDay)
            _hasDueDate = State(initialValue: false)
        }
        
        _priority = State(initialValue: task.priority)
        
        if let assigneeId = task.assignedTo {
            _selectedAssigneeIds = State(initialValue: [assigneeId])
        }
        
        _subtasks = State(initialValue: task.subtasks ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("タスク内容")) {
                    TextField("タイトル", text: $title)
                    TextField("詳細 (任意)", text: $description)
                }
                
                Section(header: Text("チェックリスト")) {
                    ForEach($subtasks) { $subtask in
                        HStack {
                            Button {
                                subtask.isCompleted.toggle()
                            } label: {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(subtask.isCompleted ? .green : .gray)
                            }
                            .buttonStyle(.plain)
                            
                            TextField("項目名", text: $subtask.title)
                                .strikethrough(subtask.isCompleted)
                                .foregroundColor(subtask.isCompleted ? .gray : .primary)
                        }
                    }
                    .onDelete { indexSet in
                        subtasks.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        TextField("新しい項目を追加", text: $newSubtaskTitle)
                            .onSubmit {
                                addSubtask()
                            }
                        
                        if !newSubtaskTitle.isEmpty {
                            Button("追加") {
                                addSubtask()
                            }
                        }
                    }
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
                
                Section(header: Text("優先度")) {
                    Picker("優先度", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("期限")) {
                    Toggle("期限を設定", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("期限", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .environment(\.locale, Locale(identifier: "ja_JP"))
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
                    assignedTo: selectedAssigneeIds.first,
                    priority: priority,
                    subtasks: subtasks
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
    
    private func addSubtask() {
        guard !newSubtaskTitle.isEmpty else { return }
        let newSubtask = SubTask(title: newSubtaskTitle)
        subtasks.append(newSubtask)
        newSubtaskTitle = ""
    }
}
