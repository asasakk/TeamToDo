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
                        try? document.data(as: AppTask.self)
                    }
                }
            }
    }
    
    func createTask(projectId: String, title: String, description: String?, dueDate: Date?, assignedTo: String?, createdBy: String) async throws -> String {
        let task = AppTask(
            id: nil,
            title: title,
            description: description,
            dueDate: dueDate,
            isCompleted: false,
            assignedTo: assignedTo,
            createdBy: createdBy,
            createdAt: Date(),
            updatedAt: nil
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
}
