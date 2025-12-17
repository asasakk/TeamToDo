import SwiftUI

struct TaskRow: View {
    let task: AppTask
    // members is optional because MyTasksView (Cross-project) might not have member list readily available
    // or we might want to fetch it differently. For now, nil means "don't show assignee name" or just show generic.
    var members: [AppUser] = []
    let onToggle: () -> Void
    
    var assignedUser: AppUser? {
        guard let assignedTo = task.assignedTo else { return nil }
        return members.first { $0.id == assignedTo }
    }
    
    var isOverdue: Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }
                
                HStack {
                    if let assignedUser = assignedUser {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                            Text(assignedUser.displayName)
                        }
                        .font(.caption2)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(dueDate, style: .date)
                            Text(dueDate, style: .time)
                        }
                        .font(.caption2)
                        .padding(4)
                        .background(isOverdue ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                        .foregroundColor(isOverdue ? .red : .primary)
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
