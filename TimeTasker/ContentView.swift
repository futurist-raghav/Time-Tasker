//
//  ContentView.swift
//  TimeTasker
//
//  Created by Raghav Agarwal on 04/12/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    // Use environment objects from App
    @EnvironmentObject var taskViewModel: TaskListViewModel
    @EnvironmentObject var audioViewModel: AudioPlayerViewModel
    @StateObject private var blockerViewModel = AppBlockerViewModel()

    @State private var showTaskCreation = false
    @State private var showCalendar = false
    @State private var showHistory = false
    @State private var showAnalytics = false

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            VStack(spacing: 12) {
                HeaderView(showCalendar: $showCalendar, showHistory: $showHistory, showAnalytics: $showAnalytics)
                    .liquidGlassCard(cornerRadius: 20, tint: .white, tintOpacity: 0.1)

                if blockerViewModel.isMonitoring {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Focus Blocking Active")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                        Text("\(blockerViewModel.blockedAppsCount) apps + \(blockerViewModel.blockedWebsitesCount) sites blocked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .liquidGlassCard(cornerRadius: 14, tint: .green, tintOpacity: 0.16)
                }

                ViewThatFits(in: .vertical) {
                    focusSections
                    ScrollView {
                        focusSections
                    }
                    .scrollIndicators(.hidden)
                }
                .frame(maxWidth: .infinity, alignment: .top)

                MusicPlayerView(viewModel: audioViewModel)
                    .padding(14)
                    .frame(minHeight: 180, maxHeight: audioViewModel.playlist.isEmpty ? 240 : 320)
                    .liquidGlassCard(cornerRadius: 18, tint: .teal, tintOpacity: 0.08)
            }
            .padding(12)
        }
        .frame(minWidth: 520, minHeight: 720)
        .sheet(isPresented: $showTaskCreation) {
            TaskCreationView(viewModel: taskViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTaskShortcut)) { _ in
            showTaskCreation = true
        }
    }

    private var focusSections: some View {
        VStack(spacing: 12) {
            if showCalendar {
                CalendarView(viewModel: taskViewModel)
                    .padding(14)
                    .liquidGlassCard(cornerRadius: 16, tint: .cyan, tintOpacity: 0.08)
            }

            if showHistory {
                TaskHistoryView(viewModel: taskViewModel)
                    .padding(14)
                    .liquidGlassCard(cornerRadius: 16, tint: .indigo, tintOpacity: 0.08)
            }

            if showAnalytics {
                AnalyticsView(viewModel: taskViewModel)
                    .padding(14)
                    .liquidGlassCard(cornerRadius: 16, tint: .blue, tintOpacity: 0.1)
            }

            if let activeTask = taskViewModel.activeTask {
                ActiveTaskView(task: activeTask, onStop: {
                    taskViewModel.stopTask()
                })
                .padding(14)
                .liquidGlassCard(
                    cornerRadius: 16,
                    tint: activeTask.isExpired ? .red : .green,
                    tintOpacity: activeTask.isExpired ? 0.16 : 0.12
                )
            }

            TaskListView(viewModel: taskViewModel, onAddTask: {
                showTaskCreation = true
            })
            .padding(14)
            .liquidGlassCard(cornerRadius: 16, tint: .white, tintOpacity: 0.08)
        }
        .padding(.horizontal, 2)
    }
}

struct HeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    private let platform = PlatformReadinessService.shared
    @Binding var showCalendar: Bool
    @Binding var showHistory: Bool
    @Binding var showAnalytics: Bool
    @State private var timeString = ""
    @State private var dateString = ""

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Tasker")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeString)
                        .font(.system(size: 40, weight: .semibold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [.white.opacity(0.95), .white.opacity(0.65)]
                                    : [.black.opacity(0.82), .black.opacity(0.62)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Local Time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 10) {
                HeaderTogglePill(
                    title: "Calendar",
                    systemImage: showCalendar ? "calendar.circle.fill" : "calendar.circle",
                    isActive: showCalendar
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCalendar.toggle()
                        if showCalendar { showHistory = false; showAnalytics = false }
                    }
                }

                HeaderTogglePill(
                    title: "History",
                    systemImage: "clock.arrow.circlepath",
                    isActive: showHistory
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showHistory.toggle()
                        if showHistory { showCalendar = false; showAnalytics = false }
                    }
                }

                HeaderTogglePill(
                    title: "Analytics",
                    systemImage: showAnalytics ? "chart.bar.fill" : "chart.bar",
                    isActive: showAnalytics
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAnalytics.toggle()
                        if showAnalytics { showCalendar = false; showHistory = false }
                    }
                }

                Spacer()
            }

            SystemReadinessRow(
                architectureLabel: platform.architectureLabel,
                osLabel: platform.osLabel,
                runtimeLabel: platform.runtimeLabel,
                supportLabel: platform.supportLabel,
                appVersionLabel: platform.appVersionLabel,
                isRosettaTranslated: platform.isRosettaTranslated
            )
        }
        .padding(16)
        .onReceive(timer) { newTime in
            updateTime(newTime)
        }
        .onAppear {
            updateTime(Date())
        }
    }
    
    private func updateTime(_ date: Date) {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .medium
        timeString = timeFormatter.string(from: date)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        dateString = dateFormatter.string(from: date)
    }
}

struct HeaderTogglePill: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isActive ? Color.accentColor.opacity(0.24) : Color.white.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.accentColor.opacity(0.8) : Color.white.opacity(0.25), lineWidth: 1)
                )
                .foregroundColor(isActive ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct SystemReadinessRow: View {
    let architectureLabel: String
    let osLabel: String
    let runtimeLabel: String
    let supportLabel: String
    let appVersionLabel: String
    let isRosettaTranslated: Bool

    var body: some View {
        HStack(spacing: 8) {
            SystemPill(icon: "cpu", text: architectureLabel, tint: .mint)
            SystemPill(icon: "laptopcomputer", text: osLabel, tint: .blue)
            SystemPill(icon: "gauge.with.dots.needle.67percent", text: runtimeLabel, tint: isRosettaTranslated ? .orange : .green)
            SystemPill(icon: "sparkles", text: supportLabel, tint: .teal)

            Spacer()

            Text(appVersionLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
    }
}

struct SystemPill: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(tint.opacity(0.16))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.45), lineWidth: 1)
        )
        .foregroundColor(.primary)
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
            // Header row
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                    
                    // Pomodoro badge
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

            // Task info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        // Category badge
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
                        
                        // Apps count
                        Button(action: { showingRestrictionDetails.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "shield.lefthalf.filled")
                                Text("\(blockedApps.count) apps · \(blockedWebsites.count) sites")
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.secondary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Timer display
                VStack(alignment: .trailing, spacing: 2) {
                    Text(task.formattedTimeRemaining)
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .foregroundColor(timerColor)
                    
                    Text(task.pomodoroIsOnBreak ? "break time" : "remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Blocked restrictions popover
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
}
