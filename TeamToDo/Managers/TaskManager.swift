import Foundation
import Combine
import FirebaseFirestore

@MainActor
class TaskManager: ObservableObject {
    @Published var tasks: [AppTask] = []
    private let db = Firestore.firestore()
    private var projectId: String?
    
    func fetchTasks(for projectId: String) {
        self.projectId = projectId
        db.collection("projects").document(projectId).collection("tasks")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let documents = snapshot?.documents, error == nil else {
                        print("Error fetching tasks: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    self?.tasks = documents.compactMap { document in
                        var task = try? document.data(as: AppTask.self)
                        task?.projectId = projectId
                        return task
                    }
                }
            }
    }
    
    func createTask(projectId: String, title: String, description: String?, dueDate: Date?, assignedTo: String?, createdBy: String, priority: TaskPriority = .medium) async throws -> String {
        let task = AppTask(
            id: nil,
            title: title,
            description: description,
            dueDate: dueDate,
            isCompleted: false,
            assignedTo: assignedTo,
            createdBy: createdBy,
            createdAt: Date(),
            updatedAt: nil,
            priority: priority
        )
        
        let ref = try db.collection("projects").document(projectId).collection("tasks").addDocument(from: task)
        return ref.documentID
    }
    
    func updateTaskstatus(projectId: String, taskId: String, isCompleted: Bool) async throws {
        try await db.collection("projects").document(projectId).collection("tasks").document(taskId).updateData([
            "isCompleted": isCompleted,
            "updatedAt": Date()
        ])
    }
    
    func assignTask(projectId: String, taskId: String, userId: String) async throws {
        try await db.collection("projects").document(projectId).collection("tasks").document(taskId).updateData([
            "assignedTo": userId,
            "updatedAt": Date()
        ])
    }
    
    func updateTask(projectId: String, taskId: String, title: String, description: String?, dueDate: Date?, assignedTo: String?, priority: TaskPriority) async throws {
        var data: [String: Any] = [
            "title": title,
            "updatedAt": Date(),
            "priority": priority.rawValue
        ]
        
        if let description = description {
            data["description"] = description
        }
        
        if let dueDate = dueDate {
            data["dueDate"] = dueDate
        } else {
             data["dueDate"] = FieldValue.delete()
        }
        
        if let assignedTo = assignedTo {
            data["assignedTo"] = assignedTo
        }
        
        try await db.collection("projects").document(projectId).collection("tasks").document(taskId).updateData(data)
    }
    
    func deleteTask(projectId: String, taskId: String) async throws {
        try await db.collection("projects").document(projectId).collection("tasks").document(taskId).delete()
    }
    
    // 自分にアサインされたタスクを全プロジェクトから取得 (Collection Group Query)
    func fetchAssignedTasks(for userId: String) {
        db.collectionGroup("tasks")
            .whereField("assignedTo", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let documents = snapshot?.documents, error == nil else {
                        print("Error fetching assigned tasks: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    self?.tasks = documents.compactMap { document in
                        var task = try? document.data(as: AppTask.self)
                        // path: projects/{projectId}/tasks/{taskId}
                        // document.reference.parent -> tasks collection
                        // document.reference.parent.parent -> project document
                        if let projectDoc = document.reference.parent.parent {
                            task?.projectId = projectDoc.documentID
                        }
                        return task
                    }
                }
            }
    }
}
