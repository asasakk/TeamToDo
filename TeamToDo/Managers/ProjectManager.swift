import Foundation
import Combine
import FirebaseFirestore

@MainActor
class ProjectManager: ObservableObject {
    @Published var projects: [Project] = []
    private let db = Firestore.firestore()
    
    func fetchProjects(for orgId: String) {
        db.collection("projects")
            .whereField("orgId", isEqualTo: orgId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let documents = snapshot?.documents, error == nil else {
                        print("Error fetching projects: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    self?.projects = documents.compactMap { document in
                        try? document.data(as: Project.self)
                    }
                }
            }
    }
    
    func createProject(orgId: String, name: String, description: String?, memberIds: [String]) async throws {
        let project = Project(
            id: nil,
            orgId: orgId,
            name: name,
            description: description,
            memberIds: memberIds,
            createdAt: Date()
        )
        
        try db.collection("projects").addDocument(from: project)
    }
    
    func joinProject(projectId: String, userId: String) async throws {
        try await db.collection("projects").document(projectId).updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
    }
}
