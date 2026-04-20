//
//  ContentView.swift
//  TimeTasker
//
//  Created by Raghav Agarwal on 04/12/25.
//

import SwiftUI
import Combine
import AppKit

private enum DashboardSection: String, CaseIterable, Identifiable {
    case today = "Today"
    case calendar = "Calendar"
    case history = "History"
    case analytics = "Analytics"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .today:
            return "checklist"
        case .calendar:
            return "calendar"
        case .history:
            return "clock.arrow.circlepath"
        case .analytics:
            return "chart.bar"
        }
    }

    var subtitle: String {
        switch self {
        case .today:
            return "What to do next"
        case .calendar:
            return "Deadlines and due dates"
        case .history:
            return "Completed sessions"
        case .analytics:
            return "Progress and trends"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var taskViewModel: TaskListViewModel
    @EnvironmentObject var audioViewModel: AudioPlayerViewModel
    @EnvironmentObject var displaySettings: AppDisplaySettings
    @StateObject private var blockerViewModel = AppBlockerViewModel()

    @State private var showTaskCreation = false
    @State private var selectedSection: DashboardSection? = .today
    @State private var searchQuery = ""
    @State private var selectedTaskID: Task.ID?
    @State private var splitVisibility: NavigationSplitViewVisibility = .all
    private let widgetCommandBridge = WidgetCommandBridge.shared

    private var filteredTasks: [Task] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return taskViewModel.tasks
        }

        return taskViewModel.tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(query)
                || task.category.rawValue.localizedCaseInsensitiveContains(query)
                || task.notes.localizedCaseInsensitiveContains(query)
                || task.resources.contains(where: { $0.name.localizedCaseInsensitiveContains(query) })
        }
    }

    private var selectedTask: Task? {
        if let selectedTaskID {
            return taskViewModel.tasks.first(where: { $0.id == selectedTaskID })
        }

        return taskViewModel.activeTask ?? filteredTasks.first
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = max(0.5, displaySettings.interfaceScale)
            let unscaledWidth = max(proxy.size.width / scale, 1)
            let unscaledHeight = max(proxy.size.height / scale, 1)

            navigationShell(logicalWidth: unscaledWidth)
                .frame(width: unscaledWidth, height: unscaledHeight, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .onAppear {
                    updateSelection(with: taskViewModel.tasks)
                    updateSplitVisibility(for: unscaledWidth)
                    handlePendingWidgetCommand()
                }
                .onChange(of: unscaledWidth) { _, newWidth in
                    updateSplitVisibility(for: newWidth)
                }
        }
    }

    private func navigationShell(logicalWidth: CGFloat) -> some View {
        NavigationSplitView(columnVisibility: $splitVisibility) {
            sidebar
                .navigationSplitViewColumnWidth(
                    min: 180,
                    ideal: min(230, logicalWidth * 0.22),
                    max: 260
                )
        } content: {
            contentColumn
                .navigationSplitViewColumnWidth(
                    min: logicalWidth < 980 ? 440 : 560,
                    ideal: logicalWidth < 980 ? 520 : 760,
                    max: logicalWidth
                )
        } detail: {
            inspectorColumn
                .navigationSplitViewColumnWidth(
                    min: logicalWidth < 980 ? 260 : 300,
                    ideal: logicalWidth < 980 ? 290 : 340,
                    max: logicalWidth
                )
        }
        .navigationSplitViewStyle(.prominentDetail)
        .searchable(text: $searchQuery, placement: .toolbar, prompt: "Search tasks")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showTaskCreation = true }) {
                    Label("New Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("toolbar.newTask")

                Button(action: startFocusFromSelection) {
                    Label("Start Focus", systemImage: "timer")
                }
                .buttonStyle(.bordered)
                .disabled(filteredTasks.allSatisfy { $0.isExpired })
                .accessibilityIdentifier("toolbar.startFocus")
            }

            ToolbarItem(placement: .automatic) {
                Button(action: cycleSection) {
                    Label("Next View", systemImage: "arrow.triangle.2.circlepath")
                }
                .help("Cycle dashboard section")
            }
        }
        .background {
            LiquidGlassBackground()
        }
        .sheet(isPresented: $showTaskCreation) {
            TaskCreationView(viewModel: taskViewModel)
                .frame(minWidth: 620, minHeight: 700)
                .interfaceScaled()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTaskShortcut)) { _ in
            showTaskCreation = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDashboardSection)) { notification in
            guard let target = notification.userInfo?["section"] as? String,
                  let section = DashboardSection(rawValue: target) else {
                return
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
        }
        .onReceive(taskViewModel.$tasks) { tasks in
            updateSelection(with: tasks)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            handlePendingWidgetCommand()
        }
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(DashboardSection.allCases) { section in
                    SidebarSectionButton(
                        section: section,
                        isSelected: (selectedSection ?? .today) == section,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSection = section
                            }
                        }
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(10)
        }
        .navigationTitle("Time Tasker")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch selectedSection ?? .today {
        case .today:
            TodayDashboardView(
                viewModel: taskViewModel,
                blockerViewModel: blockerViewModel,
                searchQuery: searchQuery,
                selectedTaskID: $selectedTaskID,
                onAddTask: { showTaskCreation = true }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Today")
        case .calendar:
            ScrollView {
                CalendarView(viewModel: taskViewModel)
                    .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Calendar")
        case .history:
            ScrollView {
                TaskHistoryView(viewModel: taskViewModel)
                    .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("History")
        case .analytics:
            ScrollView {
                AnalyticsView(viewModel: taskViewModel)
                    .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Analytics")
        }
    }

    private var inspectorColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if blockerViewModel.isMonitoring {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Focus Blocking Active")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.green)
                        Spacer()
                    }

                    Text("\(blockerViewModel.blockedAppsCount) apps and \(blockerViewModel.blockedWebsitesCount) sites currently blocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let activeTask = taskViewModel.activeTask {
                    ActiveTaskView(task: activeTask, onStop: {
                        taskViewModel.stopTask()
                    })
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("No active focus session", systemImage: "moon.zzz")
                            .font(.subheadline.weight(.medium))
                        Text("Pick a task and start focus to pin live session status here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .contentSurface(cornerRadius: 12, tint: .teal, emphasis: 0.05)
                }

                if (selectedSection ?? .today) != .today {
                    VStack(spacing: 10) {
                        DashboardMetricCard(
                            title: "Pending",
                            value: "\(taskViewModel.tasks.filter { !$0.isExpired }.count)",
                            systemImage: "hourglass",
                            tint: .blue
                        )

                        DashboardMetricCard(
                            title: "Completed",
                            value: "\(taskViewModel.taskHistory.count)",
                            systemImage: "checkmark.circle",
                            tint: .green
                        )

                        DashboardMetricCard(
                            title: "Today Focus",
                            value: taskViewModel.todayFocusTimeFormatted,
                            systemImage: "clock.badge",
                            tint: .orange
                        )
                    }
                }

                MusicPlayerView(viewModel: audioViewModel)
                    .padding(12)
                    .contentSurface(cornerRadius: 14, tint: .teal, emphasis: 0.04)
            }
            .padding(16)
        }
        .navigationTitle("Inspector")
        .frame(minWidth: 300, idealWidth: 340, maxWidth: .infinity, alignment: .leading)
    }

    private func startFocusFromSelection() {
        if let selectedTask {
            taskViewModel.startTask(selectedTask)
            selectedTaskID = selectedTask.id
            return
        }

        if let fallback = filteredTasks.first(where: { !$0.isExpired }) {
            taskViewModel.startTask(fallback)
            selectedTaskID = fallback.id
        }
    }

    private func cycleSection() {
        let all = DashboardSection.allCases
        guard let selectedSection else {
            self.selectedSection = all.first
            return
        }

        guard let index = all.firstIndex(of: selectedSection) else {
            self.selectedSection = all.first
            return
        }

        let nextIndex = all.index(after: index)
        self.selectedSection = nextIndex == all.endIndex ? all.first : all[nextIndex]
    }

    private func updateSplitVisibility(for width: CGFloat) {
        if width < 980 {
            splitVisibility = .doubleColumn
        } else {
            splitVisibility = .all
        }
    }

    private func updateSelection(with tasks: [Task]) {
        if let selectedTaskID, !tasks.contains(where: { $0.id == selectedTaskID }) {
            self.selectedTaskID = nil
        }

        if self.selectedTaskID == nil {
            self.selectedTaskID = taskViewModel.activeTask?.id ?? filteredTasks.first?.id
        }
    }

    private func handlePendingWidgetCommand() {
        guard let command = widgetCommandBridge.consumePendingCommand() else {
            return
        }

        switch command.action {
        case .openToday:
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = .today
            }
        case .openTask:
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = .today
            }

            if let taskID = command.taskID,
               let uuid = UUID(uuidString: taskID),
               taskViewModel.tasks.contains(where: { $0.id == uuid }) {
                selectedTaskID = uuid
            }
        case .openFocus:
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = .today
            }
        case .openQuickAdd:
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = .today
            }
            showTaskCreation = true
        }
    }
}

private struct SidebarSectionButton: View {
    let section: DashboardSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: section.systemImage)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(section.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentSurface(
                cornerRadius: 10,
                tint: isSelected ? .accentColor : .secondary,
                emphasis: isSelected ? 0.12 : 0.03,
                strokeOpacity: isSelected ? 0.95 : 0.55,
                shadowOpacity: 0.05
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TodayDashboardView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @ObservedObject var blockerViewModel: AppBlockerViewModel
    let searchQuery: String
    @Binding var selectedTaskID: Task.ID?
    let onAddTask: () -> Void

    private var dueSoonTasks: [Task] {
        let now = Date()
        let horizon = now.addingTimeInterval(2 * 3600)

        return viewModel.tasks
            .filter { !$0.isExpired && !$0.isActive && $0.deadline <= horizon }
            .sorted { $0.deadline < $1.deadline }
    }

    private var nextActionTasks: [Task] {
        let candidates = viewModel.tasks
            .filter { !$0.isExpired && !$0.isActive }
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority {
                    return lhs.deadline < rhs.deadline
                }

                return priorityRank(lhs.priority) > priorityRank(rhs.priority)
            }

        if dueSoonTasks.isEmpty {
            return Array(candidates.prefix(6))
        }

        return Array(dueSoonTasks.prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            todayStrip

            if blockerViewModel.isMonitoring {
                HStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.green)
                    Text("Blocking profile enforced")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(blockerViewModel.blockedAppsCount) apps · \(blockerViewModel.blockedWebsitesCount) sites")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .contentSurface(cornerRadius: 14, tint: .green, emphasis: 0.08)
            }

            if !nextActionTasks.isEmpty {
                upNextRail
            }

            TaskListView(
                viewModel: viewModel,
                onAddTask: onAddTask,
                searchQuery: searchQuery,
                selectedTaskID: $selectedTaskID
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(14)
            .contentSurface(cornerRadius: 16, tint: .blue, emphasis: 0.04)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var upNextRail: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("What should I do next?")
                    .font(.headline)

                Spacer()

                Button(action: startTopTask) {
                    Label("Start Top Task", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(nextActionTasks) { task in
                        TodayTaskChip(
                            task: task,
                            isSelected: selectedTaskID == task.id,
                            action: {
                                selectedTaskID = task.id
                            }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .contentSurface(cornerRadius: 14, tint: .indigo, emphasis: 0.06)
    }

    private func startTopTask() {
        guard let task = nextActionTasks.first else { return }
        selectedTaskID = task.id
        viewModel.startTask(task)
    }

    private func priorityRank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }

    private var todayStrip: some View {
        HStack(spacing: 10) {
            DashboardMetricCard(
                title: "Active",
                value: viewModel.activeTask == nil ? "0" : "1",
                systemImage: "timer",
                tint: .green
            )

            DashboardMetricCard(
                title: "Due Soon",
                value: "\(dueSoonTasks.count)",
                systemImage: "clock.badge.exclamationmark",
                tint: .orange
            )

            DashboardMetricCard(
                title: "Completed Today",
                value: "\(viewModel.tasksCompletedToday)",
                systemImage: "checkmark.seal",
                tint: .blue
            )
        }
    }
}

private struct TodayTaskChip: View {
    let task: Task
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: task.category.iconName)
                    .foregroundColor(priorityTint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(task.formattedTimeRemaining)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(width: 240, alignment: .leading)
            .contentSurface(
                cornerRadius: 10,
                tint: isSelected ? .accentColor : priorityTint,
                emphasis: isSelected ? 0.12 : 0.06,
                strokeOpacity: 0.9,
                shadowOpacity: 0.08
            )
        }
        .buttonStyle(.plain)
    }

    private var priorityTint: Color {
        switch task.priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.monospacedDigit())
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentSurface(cornerRadius: 12, tint: tint, emphasis: 0.08)
    }
}

struct ActiveTaskView: View {
    let task: Task
    let onStop: () -> Void

    @State private var showingRestrictionDetails = false

    private var blockedApps: [Resource] {
        task.resources.filter { $0.type == .application }
    }

    private var blockedWebsites: [Resource] {
        task.resources.filter { $0.type == .website }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)

                    if task.isPomodoroMode {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text(task.pomodoroStatusText)
                        }
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.pomodoroIsOnBreak ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(task.pomodoroIsOnBreak ? .blue : .orange)
                        .cornerRadius(4)
                    }
                }

                Spacer()

                Button(action: onStop) {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: task.category.iconName)
                            Text(task.category.rawValue)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)

                        Button(action: { showingRestrictionDetails.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "shield.lefthalf.filled")
                                Text("\(blockedApps.count) apps · \(blockedWebsites.count) sites")
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12))
                            .foregroundColor(.secondary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(task.formattedTimeRemaining)
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .foregroundColor(timerColor)

                    Text(task.pomodoroIsOnBreak ? "break time" : "remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if showingRestrictionDetails {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Blocked During Focus")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    if blockedApps.isEmpty && blockedWebsites.isEmpty {
                        Text("No restrictions selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !blockedApps.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(blockedApps) { resource in
                                    HStack(spacing: 4) {
                                        Image(systemName: "app.fill")
                                            .font(.caption)
                                        Text(resource.name)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.12))
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }

                    if !blockedWebsites.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(blockedWebsites) { resource in
                                    HStack(spacing: 4) {
                                        Image(systemName: "globe")
                                            .font(.caption)
                                        Text(resource.name)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.15))
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        if task.isExpired {
            return .red
        } else if task.pomodoroIsOnBreak {
            return .blue
        } else {
            return .green
        }
    }

    private var statusText: String {
        if task.isExpired {
            return "Time Expired"
        } else if task.pomodoroIsOnBreak {
            return "Break Time"
        } else {
            return "Active Task"
        }
    }

    private var timerColor: Color {
        if task.isExpired {
            return .red
        } else if task.pomodoroIsOnBreak {
            return .blue
        } else {
            return .primary
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskListViewModel())
        .environmentObject(AudioPlayerViewModel())
        .environmentObject(AppDisplaySettings())
}

