import SwiftUI

struct TaskHistoryView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @State private var filterCategory: Category? = nil
    
    var filteredHistory: [CompletedTask] {
        if let category = filterCategory {
            return viewModel.taskHistory.filter { $0.category == category }
        }
        return viewModel.taskHistory
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.accentColor)
                Text("Task History")
                    .font(.headline)
                
                Spacer()
                
                // Filter picker
                Menu {
                    Button("All Categories") {
                        filterCategory = nil
                    }
                    Divider()
                    ForEach(Category.allCases, id: \.self) { category in
                        Button(action: { filterCategory = category }) {
                            Label(category.rawValue, systemImage: category.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(filterCategory?.rawValue ?? "All")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
            }
            
            if filteredHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No completed tasks yet")
                        .foregroundColor(.secondary)
                    Text("Complete tasks to see them here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredHistory) { task in
                            TaskHistoryRow(task: task, onRestart: {
                                restartTask(task)
                            })
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            
            // Summary
            if !viewModel.taskHistory.isEmpty {
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(viewModel.taskHistory.count) total")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("tasks completed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(formatTotalTime())
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("total focus time")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func restartTask(_ completedTask: CompletedTask) {
        let newTask = Task(
            title: completedTask.title,
            deadline: Date().addingTimeInterval(3600), // 1 hour from now
            category: completedTask.category
        )
        viewModel.addTask(newTask)
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = viewModel.taskHistory.reduce(0) { $0 + $1.focusTime }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct TaskHistoryRow: View {
    let task: CompletedTask
    let onRestart: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            Image(systemName: task.wasSuccessful ? "checkmark.circle.fill" : "clock.badge.exclamationmark")
                .foregroundColor(task.wasSuccessful ? .green : .orange)
            
            // Task info
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Category
                    HStack(spacing: 2) {
                        Image(systemName: task.category.iconName)
                        Text(task.category.rawValue)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    
                    // Focus time
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(formatFocusTime(task.focusTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Date
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDate(task.completedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: onRestart) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatFocusTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    TaskHistoryView(viewModel: TaskListViewModel())
        .frame(width: 400)
        .padding()
}
