import SwiftUI

struct MemberSelectionView: View {
    let members: [AppUser]
    @Binding var selectedAssigneeIds: Set<String>
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
                    if selectedAssigneeIds.count == members.count {
                        selectedAssigneeIds.removeAll()
                    } else {
                        selectedAssigneeIds = Set(members.compactMap { $0.id })
                    }
                } label: {
                    HStack {
                        Text(selectedAssigneeIds.count == members.count ? "すべて解除" : "全員を選択")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedAssigneeIds.count == members.count {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                ForEach(filteredMembers) { member in
                    Button {
                        guard let id = member.id else { return }
                        if selectedAssigneeIds.contains(id) {
                            selectedAssigneeIds.remove(id)
                        } else {
                            selectedAssigneeIds.insert(id)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(member.displayName)
                                    .foregroundColor(.primary)
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if let id = member.id {
                                Image(systemName: selectedAssigneeIds.contains(id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedAssigneeIds.contains(id) ? .blue : .gray)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "メンバーを検索")
            .navigationTitle("担当者を選択 (複数可)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }
}

