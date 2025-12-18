import SwiftUI

struct CalendarView: View {
    // 依存関係をOrganizationManagerに変更
    @EnvironmentObject var orgManager: OrganizationManager
    @StateObject private var projectManager = ProjectManager()
    @StateObject private var taskManager = TaskManager()
    
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var selectedOrgId: String?
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]
    @State private var members: [String: AppUser] = [:] // memberId -> AppUser
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 組織選択Picker (組織が複数ある場合のみ、あるいは常に表示)
                if !orgManager.organizations.isEmpty {
                    Picker("組織", selection: $selectedOrgId) {
                        ForEach(orgManager.organizations) { org in
                            Text(org.name).tag(org.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.top)
                    .onChange(of: selectedOrgId) { _, newValue in
                        if let orgId = newValue {
                            fetchOrganizationTasks(orgId: orgId)
                        }
                    }
                }
                
                // 月切り替えヘッダー
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                    
                    Text(monthString(from: currentMonth))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .padding()
                    }
                }
                .padding(.bottom)
                
                // 曜日ヘッダー
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 8)
                
                // カレンダーグリッド
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            VStack(spacing: 4) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 16))
                                    .foregroundColor(isSameDay(date, selectedDate) ? .white : (isToday(date) ? .blue : .primary))
                                    .frame(width: 30, height: 30)
                                    .background(isSameDay(date, selectedDate) ? Color.blue : Color.clear)
                                    .clipShape(Circle())
                                
                                // タスクマーカー（担当者カラー）
                                HStack(spacing: 2) {
                                    ForEach(tasksForDate(date).prefix(3)) { task in
                                        if let assignedTo = task.assignedTo {
                                            Circle()
                                                .fill(Color.memberColor(userId: assignedTo))
                                                .frame(width: 4, height: 4)
                                        } else {
                                            Circle()
                                                .fill(Color.gray)
                                                .frame(width: 4, height: 4)
                                        }
                                    }
                                }
                            }
                            .onTapGesture {
                                selectedDate = date
                            }
                        } else {
                            Text("")
                                .frame(width: 30, height: 30) // Placeholder
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                List {
                    // Section 1: Selected Date Tasks
                    Section(header: Text(dateFormatter.string(from: selectedDate))) {
                        if tasksForDate(selectedDate).isEmpty {
                             Text("予定はありません")
                                 .foregroundStyle(.secondary)
                                 .listRowSeparator(.hidden)
                        } else {
                            ForEach(tasksForDate(selectedDate)) { task in
                TaskRowCalendar(task: task, projectName: getProjectName(for: task), assignee: members[task.assignedTo ?? ""], iconColor: Color.memberColor(userId: task.assignedTo))
                            }
                        }
                    }
                    
                    // Section 2: No Due Date Tasks
                    if !noDueDateTasks.isEmpty {
                        Section(header:
                            Button(action: {
                                withAnimation { isNoDateExpanded.toggle() }
                            }) {
                                HStack {
                                    Text("期限なし")
                                    Spacer()
                                    Image(systemName: isNoDateExpanded ? "chevron.down" : "chevron.right")
                                }
                            }
                            .foregroundColor(.secondary)
                        ) {
                            if isNoDateExpanded {
                                ForEach(noDueDateTasks) { task in
                                    TaskRowCalendar(task: task, projectName: getProjectName(for: task), assignee: members[task.assignedTo ?? ""], iconColor: Color.memberColor(userId: task.assignedTo))
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            // ナビゲーションタイトルを削除してスペースを確保
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // 空のViewでタイトル領域を上書き、またはタイトルを非表示にする
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar) 
            .onAppear {
                // 初期表示時に最初の組織を選択
                if selectedOrgId == nil, let firstOrg = orgManager.organizations.first {
                    selectedOrgId = firstOrg.id
                    fetchOrganizationTasks(orgId: firstOrg.id!)
                } else if let orgId = selectedOrgId {
                    fetchOrganizationTasks(orgId: orgId) // 既に選択されていればリロード
                }
            }
            .onChange(of: projectManager.projects) { _, _ in
                updateTasks()
                fetchMembers()
            }
        }
    }
    
    @State private var isNoDateExpanded = true
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }
    
    // MARK: - Helpers
    
    private var noDueDateTasks: [AppTask] {
        taskManager.tasks.filter { $0.dueDate == nil && !$0.isCompleted }
    }
    
    private func fetchOrganizationTasks(orgId: String) {
        // 1. 組織のプロジェクトを取得
        projectManager.fetchProjects(for: orgId) // これは非同期リスナーだが、projectManager.projectsが更新される
        
        // プロジェクト取得は非同期なので、少し待ってからタスク取得するか、ProjectManagerのprojectsを監視する必要があるが、
        // ProjectManagerは@StateObjectなのでView再描画される。
        // ここでは単純化のため、ProjectManagerに一括取得メソッド（async）があれば良いが、既存はリスナーベース。
        // 暫定対応: プロジェクト一覧の変更を検知してタスク取得を行う
    }
    // プロジェクト一覧が変わったらタスクを再取得
    private func updateTasks() {
        let projectIds = projectManager.projects.compactMap { $0.id }
        taskManager.fetchTasks(for: projectIds)
    }
    
    private func fetchMembers() {
        // プロジェクトのメンバーIDを収集
        let allMemberIds = Set(projectManager.projects.flatMap { $0.memberIds })
        Task {
            let users = await FirebaseManager.shared.fetchUsers(uids: Array(allMemberIds))
            
            var newMembers: [String: AppUser] = [:]
            for user in users {
                if let uid = user.id {
                    newMembers[uid] = user
                }
            }
            // Add current user if not in list (might be needed?)
            if let currentUser = FirebaseManager.shared.currentUser, let uid = currentUser.id {
                 newMembers[uid] = currentUser
            }
            
            await MainActor.run {
                self.members = newMembers
            }
        }
    }
    
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1 // 1(Sun) -> 0
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func tasksForDate(_ date: Date) -> [AppTask] {
        taskManager.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return isSameDay(dueDate, date)
        }
    }
    
    private func toggleTaskStatus(_ task: AppTask) {
        // TaskモデルにprojectIdが含まれている必要がある (TaskManager.fetchTasksでセットしている)
        guard let projectId = task.projectId, let taskId = task.id else { return }
        Task {
            try? await taskManager.updateTaskstatus(projectId: projectId, taskId: taskId, isCompleted: !task.isCompleted)
        }
    }
    
    private func getProjectName(for task: AppTask) -> String? {
        // projectIdからプロジェクト名を探す
        guard let projectId = task.projectId else { return nil }
        return projectManager.projects.first { $0.id == projectId }?.name
    }
    
    // private func getMemberColor(userId: String?) -> Color { ... } removed to use Color.memberColor extension
}

struct TaskRowCalendar: View {
    let task: AppTask
    let projectName: String?
    let assignee: AppUser?
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                if let projectName = projectName {
                    Text(projectName)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // 担当者名表示
            if let user = assignee {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(iconColor)
                    Text(user.displayName)
                }
                .font(.caption2)
                .padding(4)
                .background(iconColor.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}
