//
//  TimeTaskerApp.swift
//  TimeTasker
//
//  Created by Raghav Agarwal on 04/12/25.
//

import SwiftUI
import AppKit

#if arch(x86_64)
#error("Time Tasker 4.1 and later support Apple Silicon (arm64) only.")
#endif

@main
struct TimeTaskerApp: App {
    // Shared ViewModels for app-wide access
    @StateObject private var taskViewModel = TaskListViewModel()
    @StateObject private var audioViewModel = AudioPlayerViewModel()
    
    var body: some Scene {
        WindowGroup("Time Tasker") {
            ContentView()
                .environmentObject(taskViewModel)
                .environmentObject(audioViewModel)
                .frame(minWidth: 500, minHeight: 700)
        }
        .defaultSize(width: 1180, height: 860)
        .windowResizability(.contentMinSize)
        .commands {
            // Task commands
            CommandGroup(after: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .newTaskShortcut, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            
            // Music playback commands
            CommandMenu("Playback") {
                Button("Play / Pause") {
                    NotificationCenter.default.post(name: .musicPlayPause, object: nil)
                }
                .keyboardShortcut(" ", modifiers: [])
                
                Button("Previous Track") {
                    NotificationCenter.default.post(name: .musicPrevious, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command])
                
                Divider()
                
                Button("Skip Forward 5s") {
                    NotificationCenter.default.post(name: .musicForward, object: nil)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                
                Button("Skip Back 5s") {
                    NotificationCenter.default.post(name: .musicRewind, object: nil)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
            }
        }
        
        // Menu Bar Extra - shows timer status in menu bar
        MenuBarExtra {
            MenuBarView(taskViewModel: taskViewModel, audioViewModel: audioViewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: taskViewModel.activeTask != nil ? "clock.badge.checkmark.fill" : "clock")
                if let activeTask = taskViewModel.activeTask {
                    Text(activeTask.formattedTimeRemaining)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
        
        // Settings window
        Settings {
            SettingsView()
        }
    }
}

extension Notification.Name {
    static let newTaskShortcut = Notification.Name("newTaskShortcut")
    static let musicPlayPause = Notification.Name("musicPlayPause")
    static let musicNext = Notification.Name("musicNext")
    static let musicPrevious = Notification.Name("musicPrevious")
    static let musicForward = Notification.Name("musicForward")
    static let musicRewind = Notification.Name("musicRewind")
}
