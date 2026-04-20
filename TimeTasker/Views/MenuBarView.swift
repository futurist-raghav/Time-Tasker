import SwiftUI
import AppKit

// Menu Bar Extra for TimeTasker - Streamlined
struct MenuBarView: View {
    @ObservedObject var taskViewModel: TaskListViewModel
    @ObservedObject var audioViewModel: AudioPlayerViewModel
    @EnvironmentObject private var displaySettings: AppDisplaySettings
    @AppStorage("blockingEnabled") private var blockingEnabled = true
    @AppStorage("autoAdvanceTask") private var autoAdvanceTask = false

    private var pendingTasks: [Task] {
        taskViewModel.tasks.filter { !$0.isExpired && !$0.isActive }
    }

    private var nextSuggestedTask: Task? {
        pendingTasks.sorted { lhs, rhs in
            if lhs.priority == rhs.priority {
                return lhs.deadline < rhs.deadline
            }

            return priorityRank(lhs.priority) > priorityRank(rhs.priority)
        }.first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Active Task Quick View
            if let activeTask = taskViewModel.activeTask {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text(activeTask.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Spacer()
                        Button(action: { taskViewModel.stopTask() }) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(activeTask.formattedTimeRemaining)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Button("Complete") {
                            taskViewModel.completeTask(activeTask)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Stop") {
                            taskViewModel.stopTask()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Spacer(minLength: 0)
                    }
                }
                .padding(12)
                .contentSurface(cornerRadius: 10, tint: .green, emphasis: 0.1, strokeOpacity: 0.9, shadowOpacity: 0.08)
            } else {
                HStack {
                    Image(systemName: "moon.zzz")
                        .foregroundColor(.secondary)
                    Text("No active task")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(12)
                .contentSurface(cornerRadius: 10, tint: .secondary, emphasis: 0.04, strokeOpacity: 0.7, shadowOpacity: 0.08)
            }

            Divider()

            // Quick stats
            HStack(spacing: 16) {
                VStack {
                    Text("\(taskViewModel.tasks.filter { !$0.isExpired }.count)")
                        .font(.headline)
                    Text("Pending")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(taskViewModel.taskHistory.count)")
                        .font(.headline)
                    Text("Completed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(taskViewModel.todayFocusTimeFormatted)
                        .font(.headline)
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .contentSurface(cornerRadius: 10, tint: .blue, emphasis: 0.08, strokeOpacity: 0.85, shadowOpacity: 0.08)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Actions")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button(action: openTaskComposer) {
                        Label("New", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button(action: startNextSuggestedTask) {
                        Label("Start Next", systemImage: "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(nextSuggestedTask == nil)

                    Spacer(minLength: 0)
                }

                Toggle("Blocking Enabled", isOn: $blockingEnabled)
                    .toggleStyle(.switch)

                Toggle("Auto-advance", isOn: $autoAdvanceTask)
                    .toggleStyle(.switch)
            }
            .padding(12)
            .contentSurface(cornerRadius: 10, tint: .mint, emphasis: 0.08, strokeOpacity: 0.85, shadowOpacity: 0.08)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Navigate")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    navButton(title: "Today", icon: "checklist", section: "Today")
                    navButton(title: "Calendar", icon: "calendar", section: "Calendar")
                }

                HStack(spacing: 8) {
                    navButton(title: "History", icon: "clock.arrow.circlepath", section: "History")
                    navButton(title: "Analytics", icon: "chart.bar", section: "Analytics")
                }
            }
            .padding(12)
            .contentSurface(cornerRadius: 10, tint: .indigo, emphasis: 0.08, strokeOpacity: 0.85, shadowOpacity: 0.08)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Interface")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button("A-") {
                        displaySettings.decreaseScale()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Reset") {
                        displaySettings.resetScale()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("A+") {
                        displaySettings.increaseScale()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer(minLength: 0)

                    Text("\(displaySettings.scalePercentage)%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .contentSurface(cornerRadius: 10, tint: .orange, emphasis: 0.08, strokeOpacity: 0.85, shadowOpacity: 0.08)

            // Music controls (compact)
            if !audioViewModel.playlist.isEmpty {
                Divider()

                HStack(spacing: 12) {
                    Button(action: audioViewModel.previousSong) {
                        Image(systemName: "backward.fill")
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: audioViewModel.playOrPause) {
                        Image(systemName: audioViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: audioViewModel.nextSong) {
                        Image(systemName: "forward.fill")
                    }
                    .buttonStyle(.plain)
                    
                    Text(audioViewModel.currentSong)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentSurface(cornerRadius: 8, tint: .indigo, emphasis: 0.08, strokeOpacity: 0.8, shadowOpacity: 0.08)
            }

            Divider()

            // Actions
            VStack(spacing: 0) {
                Button(action: { openMainWindow() }) {
                    Label("Open Time Tasker", systemImage: "macwindow")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Button(action: { hideMainWindow() }) {
                    Label("Hide Main Window", systemImage: "eye.slash")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Button(action: { NSApp.terminate(nil) }) {
                    Label("Quit", systemImage: "power")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 300)
    }

    @ViewBuilder
    private func navButton(title: String, icon: String, section: String) -> some View {
        Button(action: {
            openSection(section)
        }) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func startNextSuggestedTask() {
        guard let task = nextSuggestedTask else { return }
        taskViewModel.startTask(task)
    }

    private func openTaskComposer() {
        openMainWindow()
        NotificationCenter.default.post(name: .newTaskShortcut, object: nil)
    }

    private func openSection(_ section: String) {
        openMainWindow()
        NotificationCenter.default.post(
            name: .openDashboardSection,
            object: nil,
            userInfo: ["section": section]
        )
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first(where: { $0.title.contains("Time Tasker") && $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
            return
        }

        if let window = NSApp.windows.first(where: { $0.canBecomeMain && $0.level == .normal }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func hideMainWindow() {
        if let window = NSApp.windows.first(where: { $0.title.contains("Time Tasker") && $0.canBecomeMain }) {
            window.orderOut(nil)
            return
        }

        if let fallback = NSApp.windows.first(where: { $0.canBecomeMain && $0.level == .normal }) {
            fallback.orderOut(nil)
        }
    }

    private func priorityRank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// Settings View for the popup
struct SettingsView: View {
    @AppStorage("blockingEnabled") private var blockingEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("enableSystemWideHostsBlocking") private var enableSystemWideHostsBlocking = true
    @AppStorage("autoAdvanceTask") private var autoAdvanceTask = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("appearanceMode") private var appearanceMode = 0 // 0 = System, 1 = Light, 2 = Dark
    @State private var showAdvancedPlatformDetails = false
    @EnvironmentObject private var displaySettings: AppDisplaySettings
    private let platform = PlatformReadinessService.shared
    
    var body: some View {
        Form {
            Section("Blocking") {
                Toggle("Enable App Blocking", isOn: $blockingEnabled)
                Toggle("Play Sound on Block", isOn: $soundEnabled)
                Toggle("System-wide website blocking (/etc/hosts)", isOn: $enableSystemWideHostsBlocking)
                Text("When enabled, the app may ask for admin permission during focus sessions to temporarily enforce blocked domains at system level.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Section("Tasks") {
                Toggle("Auto-advance to Next Task", isOn: $autoAdvanceTask)
            }
            
            Section("Interface") {
                Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                
                Picker("Appearance", selection: $appearanceMode) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
                .onChange(of: appearanceMode) { _, newValue in
                    applyAppearance(newValue)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Interface Scale")
                        Spacer()
                        Text("\(displaySettings.scalePercentage)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: Binding(
                            get: { Double(displaySettings.interfaceScale) },
                            set: { displaySettings.setScale(CGFloat($0)) }
                        ),
                        in: Double(displaySettings.minimumScale)...Double(displaySettings.maximumScale),
                        step: Double(displaySettings.step)
                    )

                    HStack(spacing: 8) {
                        Button("A-") {
                            displaySettings.decreaseScale()
                        }

                        Button("Reset") {
                            displaySettings.resetScale()
                        }

                        Button("A+") {
                            displaySettings.increaseScale()
                        }

                        Spacer()

                        Text("Shortcuts: Cmd +, Cmd -, Cmd 0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("Build Info") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(platform.displayVersionLabel)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Operating System")
                    Spacer()
                    Text(platform.displayOSLabel)
                        .foregroundColor(.secondary)
                }

                DisclosureGroup("Advanced Runtime Details", isExpanded: $showAdvancedPlatformDetails) {
                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text(platform.architectureLabel)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Runtime")
                        Spacer()
                        Text(platform.runtimeLabel)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Support Window")
                        Spacer()
                        Text(platform.supportLabel)
                            .foregroundColor(.secondary)
                    }
                }

                if platform.isRosettaTranslated {
                    Label("Running through Rosetta may reduce process blocking precision.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 430, height: 530)
        .navigationTitle("Settings")
        .onAppear {
            applyAppearance(appearanceMode)
        }
    }
    
    private func applyAppearance(_ mode: Int) {
        switch mode {
        case 1:
            NSApp.appearance = NSAppearance(named: .aqua)
        case 2:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil // System default
        }
    }
}

// Completed Tasks View
struct CompletedTasksView: View {
    @ObservedObject var viewModel: TaskListViewModel
    
    var completedTasks: [Task] {
        viewModel.tasks.filter { $0.isExpired && !$0.isActive }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if completedTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No completed tasks")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(completedTasks) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .strikethrough()
                                HStack {
                                    Image(systemName: task.category.iconName)
                                    Text(task.category.rawValue)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Restart task
                                if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                                    viewModel.tasks[index].isExpired = false
                                    viewModel.tasks[index].deadline = Date().addingTimeInterval(3600) // Add 1 hour
                                }
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                            }
                            .buttonStyle(.plain)
                            .help("Restart Task")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
        .navigationTitle("Completed Tasks")
    }
}
