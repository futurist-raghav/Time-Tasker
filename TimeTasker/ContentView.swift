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
    
    // Monitor for blocking status
    @State private var lastBlockedApp = ""

    @State private var showTaskCreation = false
    @State private var showCalendar = false
    @State private var showHistory = false
    @State private var showAnalytics = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with current time
            HeaderView(showCalendar: $showCalendar, showHistory: $showHistory, showAnalytics: $showAnalytics)
            
            // Show blocking status if active
            if blockerViewModel.isMonitoring {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("App Blocking Active")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(blockerViewModel.allowedAppsCount) apps allowed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
            }
            
            Divider()
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 16) {
                    // Calendar View (toggleable)
                    if showCalendar {
                        CalendarView(viewModel: taskViewModel)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    // Task History View
                    if showHistory {
                        TaskHistoryView(viewModel: taskViewModel)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    // Analytics View
                    if showAnalytics {
                        AnalyticsView(viewModel: taskViewModel)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    // Active task display (if any)
                    if let activeTask = taskViewModel.activeTask {
                        ActiveTaskView(task: activeTask, onStop: {
                            taskViewModel.stopTask()
                        })
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(activeTask.isExpired ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(activeTask.isExpired ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .padding(.top, showCalendar ? 0 : 8)
                    }

                    // Task list
                    TaskListView(viewModel: taskViewModel, onAddTask: {
                        showTaskCreation = true
                    })
                    .padding(.horizontal)
                }
            }

            Divider()
                .padding(.horizontal)

            // Music player at bottom
            MusicPlayerView(viewModel: audioViewModel)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .frame(minWidth: 520, minHeight: 720)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showTaskCreation) {
            TaskCreationView(viewModel: taskViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTaskShortcut)) { _ in
            showTaskCreation = true
        }
    }
}

struct HeaderView: View {
    @Binding var showCalendar: Bool
    @Binding var showHistory: Bool
    @Binding var showAnalytics: Bool
    @State private var currentTime = Date()
    @State private var timeString = ""
    @State private var dateString = ""

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            // Main header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Tasker")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
                
                // Large clock display
                Text(timeString)
                    .font(.system(size: 42, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            // Toolbar row
            HStack(spacing: 12) {
                // Calendar toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCalendar.toggle()
                        if showCalendar { showHistory = false; showAnalytics = false }
                    }
                }) {
                    Label("Calendar", systemImage: showCalendar ? "calendar.circle.fill" : "calendar.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(showCalendar ? .accentColor : .secondary)
                
                // History toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showHistory.toggle()
                        if showHistory { showCalendar = false; showAnalytics = false }
                    }
                }) {
                    Label("History", systemImage: showHistory ? "clock.arrow.circlepath" : "clock.arrow.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(showHistory ? .accentColor : .secondary)
                
                // Analytics toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAnalytics.toggle()
                        if showAnalytics { showCalendar = false; showHistory = false }
                    }
                }) {
                    Label("Analytics", systemImage: showAnalytics ? "chart.bar.fill" : "chart.bar")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(showAnalytics ? .accentColor : .secondary)
                
                Spacer()
            }
        }
        .padding()
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

struct ActiveTaskView: View {
    let task: Task
    let onStop: () -> Void
    
    @State private var showingAllowedApps = false

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
                        Button(action: { showingAllowedApps.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "app.badge.checkmark")
                                Text("\(task.resources.count) apps")
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
            
            // Allowed apps popover
            if showingAllowedApps {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Allowed Apps")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    if task.resources.isEmpty {
                        Text("No apps selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(task.resources) { resource in
                                    HStack(spacing: 4) {
                                        Image(systemName: "app.fill")
                                            .font(.caption)
                                        Text(resource.name)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
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
