import SwiftUI

struct MemberSelectionView: View {
    let members: [AppUser]
    @Binding var selectedAssigneeId: String?
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var filteredMembers: [AppUser] {
        if searchText.isEmpty {
            return members
        } else {
            return members.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedAssigneeId = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("未割り当て")
                            .foregroundColor(.primary)
                        if selectedAssigneeId == nil {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(filteredMembers) { member in
                    Button {
                        selectedAssigneeId = member.id
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(member.displayName)
                                    .foregroundColor(.primary)
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            if selectedAssigneeId == member.id {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "メンバーを検索")
            .navigationTitle("担当者を選択")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}
