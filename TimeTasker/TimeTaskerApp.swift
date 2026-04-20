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
#error("Time Tasker 4.3 and later support Apple Silicon (arm64) only.")
#endif

@main
struct TimeTaskerApp: App {
    // Shared ViewModels for app-wide access
    @StateObject private var taskViewModel: TaskListViewModel
    @StateObject private var audioViewModel: AudioPlayerViewModel
    @StateObject private var displaySettings: AppDisplaySettings
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

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
                .tint(Color(red: 0.22, green: 0.56, blue: 0.98))
                .frame(minWidth: 680, minHeight: 560)
        }
        .defaultSize(width: 1180, height: 860)
        .windowResizability(.automatic)
        .commands {
            // Task commands
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    presentTaskCreationWindow()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandMenu("Navigate") {
                Button("Today") {
                    openDashboardSection(.today)
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Calendar") {
                    openDashboardSection(.calendar)
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("History") {
                    openDashboardSection(.history)
                }
                .keyboardShortcut("3", modifiers: [.command])

                Button("Analytics") {
                    openDashboardSection(.analytics)
                }
                .keyboardShortcut("4", modifiers: [.command])
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
                .keyboardShortcut("+", modifiers: [.command])

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
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MenuBarView(taskViewModel: taskViewModel, audioViewModel: audioViewModel)
                .environmentObject(displaySettings)
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

    private func presentTaskCreationWindow() {
        bringPrimaryWindowToFront()
        NotificationCenter.default.post(name: .newTaskShortcut, object: nil)
    }

    private func openDashboardSection(_ destination: DashboardDestination) {
        bringPrimaryWindowToFront()
        NotificationCenter.default.post(
            name: .openDashboardSection,
            object: nil,
            userInfo: ["section": destination.rawValue]
        )
    }

    private func bringPrimaryWindowToFront() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first(where: { $0.title.contains("Time Tasker") && $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
            return
        }

        if let fallback = NSApp.windows.first(where: { $0.canBecomeMain }) {
            fallback.makeKeyAndOrderFront(nil)
        }
    }

    private static func configureUITestingEnvironmentIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") else {
            return
        }

        DataPersistenceService.resetPersistentDataForUITesting()
    }
}

private enum DashboardDestination: String {
    case today = "Today"
    case calendar = "Calendar"
    case history = "History"
    case analytics = "Analytics"
}

extension Notification.Name {
    static let newTaskShortcut = Notification.Name("newTaskShortcut")
    static let musicPlayPause = Notification.Name("musicPlayPause")
    static let musicNext = Notification.Name("musicNext")
    static let musicPrevious = Notification.Name("musicPrevious")
    static let musicForward = Notification.Name("musicForward")
    static let musicRewind = Notification.Name("musicRewind")
    static let openDashboardSection = Notification.Name("openDashboardSection")
}

final class AppDisplaySettings: ObservableObject {
    private enum Keys {
        static let interfaceScale = "interfaceScale"
    }

    let minimumScale: CGFloat = 0.75
    let maximumScale: CGFloat = 2.0
    let step: CGFloat = 0.05

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
        min(2.0, max(0.75, value))
    }
}
