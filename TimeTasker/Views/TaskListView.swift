import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskListViewModel
    let onAddTask: () -> Void
    let searchQuery: String
    @Binding private var selectedTaskID: Task.ID?

    init(
        viewModel: TaskListViewModel,
        onAddTask: @escaping () -> Void,
        searchQuery: String = "",
        selectedTaskID: Binding<Task.ID?> = .constant(nil)
    ) {
        self.viewModel = viewModel
        self.onAddTask = onAddTask
        self.searchQuery = searchQuery
        _selectedTaskID = selectedTaskID
    }

    private var visibleTasks: [Task] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return viewModel.tasks
        }

        return viewModel.tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(query)
                || task.category.rawValue.localizedCaseInsensitiveContains(query)
                || task.notes.localizedCaseInsensitiveContains(query)
        }
    }

    private var pendingCount: Int {
        visibleTasks.filter { !$0.isExpired }.count
    }

    private var expiredCount: Int {
        visibleTasks.filter { $0.isExpired }.count
    }

    private var totalRulesCount: Int {
        visibleTasks.reduce(0) { partial, task in
            partial + task.resources.count
        }
    }

    private var groupedTasks: [(title: String, tasks: [Task])] {
        let sorted = visibleTasks.sorted { $0.deadline < $1.deadline }
        let now = Date()
        let inOneHour = now.addingTimeInterval(3600)
        let inFourHours = now.addingTimeInterval(4 * 3600)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now

        let active = sorted.filter { $0.isActive }
        let nowTasks = sorted.filter { !$0.isActive && !$0.isExpired && $0.deadline <= inOneHour }
        let nextTasks = sorted.filter { !$0.isActive && !$0.isExpired && $0.deadline > inOneHour && $0.deadline <= inFourHours }
        let laterToday = sorted.filter {
            !$0.isActive
                && !$0.isExpired
                && $0.deadline > inFourHours
                && Calendar.current.isDate($0.deadline, inSameDayAs: now)
        }
        let upcoming = sorted.filter {
            !$0.isActive
                && !$0.isExpired
                && $0.deadline >= tomorrow
        }
        let expired = sorted.filter { $0.isExpired }

        var sections: [(String, [Task])] = []
        if !active.isEmpty { sections.append(("Active", active)) }
        if !nowTasks.isEmpty { sections.append(("Now", nowTasks)) }
        if !nextTasks.isEmpty { sections.append(("Next", nextTasks)) }
        if !laterToday.isEmpty { sections.append(("Later Today", laterToday)) }
        if !upcoming.isEmpty { sections.append(("Upcoming", upcoming)) }
        if !expired.isEmpty { sections.append(("Expired", expired)) }
        return sections
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            HStack(spacing: 8) {
                TaskListMetricPill(icon: "hourglass", label: "Pending", value: pendingCount, tint: .blue)
                TaskListMetricPill(icon: "exclamationmark.triangle", label: "Expired", value: expiredCount, tint: .orange)
                TaskListMetricPill(icon: "shield", label: "Rules", value: totalRulesCount, tint: .mint)
                Spacer(minLength: 0)
            }

            if visibleTasks.isEmpty {
                emptyState
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(groupedTasks, id: \.title) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)

                                VStack(spacing: 8) {
                                    ForEach(group.tasks) { task in
                                        TaskRowView(
                                            task: task,
                                            isActive: task.isActive,
                                            isSelected: selectedTaskID == task.id,
                                            onSelect: {
                                                selectedTaskID = task.id
                                            },
                                            onStart: {
                                                selectedTaskID = task.id
                                                viewModel.startTask(task)
                                            },
                                            onComplete: {
                                                viewModel.completeTask(task)
                                            },
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
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityIdentifier("tasks.section")
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .foregroundColor(.accentColor)
                Text("Tasks")
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                Text("\(visibleTasks.count)")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onAddTask) {
                Label("New Task", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityIdentifier("tasks.newTaskButton")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(.secondary.opacity(0.75))

            Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No tasks yet" : "No matches")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Create a task to start your first focus block."
                    : "Try a different keyword for title, category, or notes.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: onAddTask) {
                Label("Create Task", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(12)
        .contentSurface(cornerRadius: 12, tint: .secondary, emphasis: 0.04)
    }
}

struct TaskRowView: View {
    let task: Task
    let isActive: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    let onStart: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    private var blockedAppCount: Int {
        task.resources.filter { $0.type == .application }.count
    }

    private var blockedSiteCount: Int {
        task.resources.filter { $0.type == .website }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.priority.iconName)
                .font(.caption)
                .foregroundColor(priorityColor)
                .frame(width: 16)

            Image(systemName: task.category.iconName)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body.weight(.medium))
                    .foregroundColor(isActive ? .green : .primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(task.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(task.priority.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.2))
                        .foregroundColor(priorityColor)
                        .clipShape(Capsule())

                    if blockedAppCount > 0 {
                        Label("\(blockedAppCount)", systemImage: "app")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if blockedSiteCount > 0 {
                        Label("\(blockedSiteCount)", systemImage: "globe")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if !task.notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(task.formattedTimeRemaining)
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundColor(timeColor)

                if task.isExpired {
                    Text("expired")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }

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
        .contentSurface(
            cornerRadius: 12,
            tint: isActive ? .green : (isSelected ? .accentColor : .secondary),
            emphasis: isActive ? 0.14 : (isSelected ? 0.1 : (isHovering ? 0.07 : 0.04)),
            strokeOpacity: isActive || isSelected ? 1 : 0.8,
            shadowOpacity: 0.1
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isActive ? Color.green.opacity(0.32) : (isSelected ? Color.accentColor.opacity(0.32) : .clear), lineWidth: 1)
        )
        .onTapGesture(perform: onSelect)
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

struct TaskListMetricPill: View {
    let icon: String
    let label: String
    let value: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(label) \(value)")
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(tint.opacity(0.16))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.36), lineWidth: 1)
        )
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
            .frame(width: 560, height: 420)
            .padding()
    }
}
