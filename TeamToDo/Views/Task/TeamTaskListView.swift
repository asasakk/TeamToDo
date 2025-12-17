import SwiftUI
import FirebaseFirestore

struct TeamTaskListView: View {
    let team: Team
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var tasks: [TeamTask] = []
    @State private var newTaskTitle = ""
    
    var body: some View {
        VStack {
            // ヘッダー（招待コード表示）
            VStack {
                Text("招待コード: \(team.inviteCode)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            
            // タスク入力
            HStack {
                TextField("新しいタスクを追加...", text: $newTaskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(newTaskTitle.isEmpty)
            }
            .padding()
            
            // タスクリスト
            List {
                ForEach(tasks) { task in
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                            .onTapGesture {
                                toggleTaskStatus(task)
                            }
                        
                        Text(task.title)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .gray : .primary)
                    }
                }
                .onDelete(perform: deleteTask)
            }
        }
        .navigationTitle(team.name)
        .onAppear {
            listenForTasks()
        }
    }
    
    private func listenForTasks() {
        guard let teamId = team.id else { return }
        
        Firestore.firestore().collection("teams").document(teamId).collection("tasks")
            .order(by: "created_at", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching tasks: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.tasks = documents.compactMap { try? $0.data(as: TeamTask.self) }
            }
    }
    
    private func addTask() {
        guard let teamId = team.id, let uid = firebaseManager.currentUser?.id, !newTaskTitle.isEmpty else { return }
        
        let newTask = TeamTask(
            title: newTaskTitle,
            isCompleted: false,
            createdAt: Date(),
            createdBy: uid
        )
        
        do {
            try Firestore.firestore().collection("teams").document(teamId).collection("tasks").addDocument(from: newTask)
            newTaskTitle = ""
        } catch {
            print("Error adding task: \(error)")
        }
    }
    
    private func toggleTaskStatus(_ task: TeamTask) {
        guard let teamId = team.id, let taskId = task.id else { return }
        
        Firestore.firestore().collection("teams").document(teamId).collection("tasks").document(taskId)
            .updateData(["is_completed": !task.isCompleted])
    }
    
    private func deleteTask(at offsets: IndexSet) {
        guard let teamId = team.id else { return }
        
        offsets.forEach { index in
            let task = tasks[index]
            guard let taskId = task.id else { return }
            
            Firestore.firestore().collection("teams").document(teamId).collection("tasks").document(taskId).delete()
        }
    }
}
