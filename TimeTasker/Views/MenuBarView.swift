import SwiftUI
import AppKit

// Menu Bar Extra for TimeTasker - Streamlined
struct MenuBarView: View {
    @ObservedObject var taskViewModel: TaskListViewModel
    @ObservedObject var audioViewModel: AudioPlayerViewModel
    
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
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
            } else {
                HStack {
                    Image(systemName: "moon.zzz")
                        .foregroundColor(.secondary)
                    Text("No active task")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(12)
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
            
            Divider()
            
            // Music controls (compact)
            if !audioViewModel.playlist.isEmpty {
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
                
                Divider()
            }
            
            // Actions
            VStack(spacing: 0) {
                Button(action: { openMainWindow() }) {
                    Label("Open Time Tasker", systemImage: "macwindow")
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
        .frame(width: 260)
    }
    
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("Time") || $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// Settings View for the popup
struct SettingsView: View {
    @AppStorage("blockingEnabled") private var blockingEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("autoAdvanceTask") private var autoAdvanceTask = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("appearanceMode") private var appearanceMode = 0 // 0 = System, 1 = Light, 2 = Dark
    
    var body: some View {
        Form {
            Section("Blocking") {
                Toggle("Enable App Blocking", isOn: $blockingEnabled)
                Toggle("Play Sound on Block", isOn: $soundEnabled)
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
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 350)
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
