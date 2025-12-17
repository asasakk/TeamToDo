import SwiftUI
import FirebaseFirestore

struct TeamSelectionView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var teams: [Team] = []
    @State private var showCreateTeam = false
    @State private var showJoinTeam = false
    @State private var newTeamName = ""
    @State private var inviteCodeInput = ""
    
    var body: some View {
        NavigationStack {
            List(teams) { team in
                NavigationLink(destination: TeamTaskListView(team: team)) {
                    VStack(alignment: .leading) {
                        Text(team.name)
                            .font(.headline)
                        Text("メンバー: \(team.memberIds.count)名")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("チーム選択")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("チームを作成") { showCreateTeam = true }
                        Button("チームに参加") { showJoinTeam = true }
                        Button("ログアウト", role: .destructive) {
                            firebaseManager.signOut()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                fetchTeams()
            }
            // チーム作成アラート
            .alert("チームを作成", isPresented: $showCreateTeam) {
                TextField("チーム名", text: $newTeamName)
                Button("作成") { createTeam() }
                Button("キャンセル", role: .cancel) { }
            }
            // チーム参加アラート
            .alert("チームに参加", isPresented: $showJoinTeam) {
                TextField("招待コード (6桁)", text: $inviteCodeInput)
                Button("参加") { joinTeam() }
                Button("キャンセル", role: .cancel) { }
            }
        }
    }
    
    private func fetchTeams() {
        guard let uid = firebaseManager.currentUser?.id else { return }
        
        // 自分がメンバーになっているチームを取得
        Firestore.firestore().collection("teams")
            .whereField("memberIds", arrayContains: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching teams: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.teams = documents.compactMap { try? $0.data(as: Team.self) }
            }
    }
    
    private func createTeam() {
        guard let uid = firebaseManager.currentUser?.id, !newTeamName.isEmpty else { return }
        
        let inviteCode = String(Int.random(in: 100000...999999)) // 簡易的な6桁コード
        let newTeam = Team(
            name: newTeamName,
            ownerId: uid,
            memberIds: [uid],
            inviteCode: inviteCode
        )
        
        do {
            try Firestore.firestore().collection("teams").addDocument(from: newTeam)
            newTeamName = ""
        } catch {
            print("Error creating team: \(error)")
        }
    }
    
    private func joinTeam() {
        guard let uid = firebaseManager.currentUser?.id, !inviteCodeInput.isEmpty else { return }
        
        // 招待コードで検索
        Firestore.firestore().collection("teams")
            .whereField("inviteCode", isEqualTo: inviteCodeInput)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error finding team: \(error)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("Team not found")
                    return
                }
                
                // メンバーに追加
                document.reference.updateData([
                    "memberIds": FieldValue.arrayUnion([uid])
                ])
                inviteCodeInput = ""
            }
    }
}
