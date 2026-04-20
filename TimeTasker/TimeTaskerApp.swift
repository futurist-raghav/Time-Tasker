//
//  TimeTaskerApp.swift
//  TimeTasker
//
//  Created by Raghav Agarwal on 04/12/25.
//

import SwiftUI
import AppKit
import Combine

#if arch(x86_64)
#error("Time Tasker 4.1 and later support Apple Silicon (arm64) only.")
#endif

@main
struct TimeTaskerApp: App {
    // Shared ViewModels for app-wide access
    @StateObject private var taskViewModel: TaskListViewModel
    @StateObject private var audioViewModel: AudioPlayerViewModel
    @StateObject private var displaySettings: AppDisplaySettings

    init() {
        Self.configureUITestingEnvironmentIfNeeded()
        _taskViewModel = StateObject(wrappedValue: TaskListViewModel())
        _audioViewModel = StateObject(wrappedValue: AudioPlayerViewModel())
        _displaySettings = StateObject(wrappedValue: AppDisplaySettings())
    }
    
    var body: some Scene {
        WindowGroup("Time Tasker") {
            ContentView()
                .environmentObject(taskViewModel)
                .environmentObject(audioViewModel)
                .environmentObject(displaySettings)
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
                .keyboardShortcut("k", modifiers: [.command])
                
                Button("Previous Track") {
                    NotificationCenter.default.post(name: .musicPrevious, object: nil)
                }
                .keyboardShortcut("[", modifiers: [.command])

                Button("Next Track") {
                    NotificationCenter.default.post(name: .musicNext, object: nil)
                }
                .keyboardShortcut("]", modifiers: [.command])
                
                Divider()
                
                Button("Skip Forward 5s") {
                    NotificationCenter.default.post(name: .musicForward, object: nil)
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command])
                
                Button("Skip Back 5s") {
                    NotificationCenter.default.post(name: .musicRewind, object: nil)
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command])
            }

            CommandMenu("View") {
                Button("Increase Interface Size") {
                    displaySettings.increaseScale()
                }
                .keyboardShortcut("=", modifiers: [.command])

                Button("Decrease Interface Size") {
                    displaySettings.decreaseScale()
                }
                .keyboardShortcut("-", modifiers: [.command])

                Button("Reset Interface Size") {
                    displaySettings.resetScale()
                }
                .keyboardShortcut("0", modifiers: [.command])
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
                .environmentObject(displaySettings)
        }
    }

    private static func configureUITestingEnvironmentIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") else {
            return
        }

        let defaults = UserDefaults.standard
        let keysToClear = [
            "SavedTasksArray",
            "taskHistory",
            "lastAnalyticsDate",
            "totalFocusTimeToday",
            "tasksCompletedToday",
            "currentStreak"
        ]

        for key in keysToClear {
            defaults.removeObject(forKey: key)
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

final class AppDisplaySettings: ObservableObject {
    private enum Keys {
        static let interfaceScale = "interfaceScale"
    }

    let minimumScale: CGFloat = 0.85
    let maximumScale: CGFloat = 1.35
    let step: CGFloat = 0.1

    @Published private(set) var interfaceScale: CGFloat

    init() {
        let storedScale = UserDefaults.standard.object(forKey: Keys.interfaceScale) as? Double ?? 1.0
        interfaceScale = Self.clamp(CGFloat(storedScale))
    }

    var scalePercentage: Int {
        Int((interfaceScale * 100).rounded())
    }

    func setScale(_ newScale: CGFloat) {
        let clamped = Self.clamp(newScale)
        guard abs(clamped - interfaceScale) > 0.0001 else { return }
        interfaceScale = clamped
        UserDefaults.standard.set(Double(clamped), forKey: Keys.interfaceScale)
    }

    func increaseScale() {
        setScale(interfaceScale + step)
    }

    func decreaseScale() {
        setScale(interfaceScale - step)
    }

    func resetScale() {
        setScale(1.0)
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        min(1.35, max(0.85, value))
    }
}
