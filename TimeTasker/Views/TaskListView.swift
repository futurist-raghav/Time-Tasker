import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskListViewModel
    let onAddTask: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.accentColor)
                    Text("Tasks")
                        .font(.headline)
                    
                    if !viewModel.tasks.isEmpty {
                        Text("(\(viewModel.tasks.count))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: onAddTask) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New Task")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.top, 8)

            if viewModel.tasks.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    VStack(spacing: 4) {
                        Text("No tasks yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Create a task to start focusing")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    Button(action: onAddTask) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Your First Task")
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            } else {
                // Task list
                VStack(spacing: 8) {
                    ForEach(viewModel.tasks) { task in
                        TaskRowView(
                            task: task,
                            isActive: task.isActive,
                            onStart: { viewModel.startTask(task) },
                            onComplete: { viewModel.completeTask(task) },
                            onDelete: {
                                if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                                    viewModel.deleteTask(at: IndexSet(integer: index))
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: Task
    let isActive: Bool
    let onStart: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Image(systemName: task.priority.iconName)
                .font(.caption)
                .foregroundColor(priorityColor)
                .frame(width: 16)
            
            // Category icon
            Image(systemName: task.category.iconName)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(.body, weight: .medium))
                    .foregroundColor(isActive ? .green : .primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Category
                    Text(task.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Priority badge
                    Text(task.priority.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(priorityColor.opacity(0.2))
                        .foregroundColor(priorityColor)
                        .cornerRadius(3)
                    
                    // Resources
                    if task.resources.count > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "app.badge.checkmark")
                                .font(.caption2)
                            Text("\(task.resources.count)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    // Notes indicator
                    if !task.notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Time remaining
            VStack(alignment: .trailing, spacing: 2) {
                Text(task.formattedTimeRemaining)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(timeColor)
                
                if task.isExpired {
                    Text("expired")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            // Action buttons
            HStack(spacing: 6) {
                if !isActive {
                    Button(action: onStart) {
                        Image(systemName: "play.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .help("Start this task")
                } else {
                    Button(action: onComplete) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.small)
                    .help("Mark as complete")
                }
                
                // Delete button (on hover)
                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete task")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.green.opacity(0.1) : (isHovering ? Color.secondary.opacity(0.08) : Color.secondary.opacity(0.05)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button(action: onStart) {
                Label("Start Task", systemImage: "play.fill")
            }
            .disabled(isActive)
            
            Button(action: onComplete) {
                Label("Mark Complete", systemImage: "checkmark.circle")
            }
            
            Divider()
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    private var statusColor: Color {
        if isActive {
            return .green
        } else if task.isExpired {
            return .red
        } else {
            return .orange
        }
    }
    
    private var timeColor: Color {
        if task.isExpired {
            return .red
        } else if isActive {
            return .green
        } else {
            return .primary
        }
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = TaskListViewModel()
        vm.tasks = [
            Task(title: "Build app", deadline: Date().addingTimeInterval(3600), category: .coding),
            Task(title: "Write docs", deadline: Date().addingTimeInterval(7200), category: .writing)
        ]
        return TaskListView(viewModel: vm, onAddTask: {})
            .frame(width: 480, height: 320)
            .padding()
    }
}
