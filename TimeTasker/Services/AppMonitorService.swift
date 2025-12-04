import Foundation
import AppKit
import Combine

class AppMonitorService: ObservableObject {
    static let shared = AppMonitorService()

    @Published var allowedApps: Set<String> = []
    @Published var blockedAppName: String = ""
    @Published var isMonitoring = false
    
    private var workspace = NSWorkspace.shared
    private var notificationObserver: Any?

    // System apps that should never be blocked
    private let systemApps: Set<String> = [
        "Finder",
        "System Settings",
        "System Preferences",
        "TimeTasker",
        "Time Tasker",
        "SecurityAgent",
        "loginwindow",
        "Notification Center",
        "NotificationCenter",
        "Control Center",
        "ControlCenter",
        "Spotlight",
        "SystemUIServer",
        "Dock",
        "AirPlayUIAgent",
        "CoreServicesUIAgent",
        "TextInputMenuAgent",
        "universalAccessAuthWarn"
    ]

    private init() {
        setupMonitoring()
    }

    private func setupMonitoring() {
        // Use NSWorkspace activation notifications to detect app switches
        notificationObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
        print("🔍 App monitoring observer set up")
    }
    
    private func handleAppActivation(_ notification: Notification) {
        guard isMonitoring else { return }
        
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let appName = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
        let bundleID = app.bundleIdentifier ?? ""
        
        print("📱 App activated: \(appName) (\(bundleID))")
        
        // Check after a short delay to avoid false positives during app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.checkAndBlockIfNeeded(app: app, appName: appName, bundleID: bundleID)
        }
    }
    
    private func checkAndBlockIfNeeded(app: NSRunningApplication, appName: String, bundleID: String) {
        guard isMonitoring else { return }
        
        // Check if app is in system apps
        if systemApps.contains(appName) {
            print("✅ System app allowed: \(appName)")
            return
        }
        
        // Check if app name matches allowed apps (case-insensitive)
        let isAllowed = allowedApps.contains { allowedName in
            appName.lowercased() == allowedName.lowercased() ||
            bundleID.lowercased().contains(allowedName.lowercased()) ||
            allowedName.lowercased().contains(appName.lowercased())
        }
        
        if isAllowed {
            print("✅ Allowed app: \(appName)")
            return
        }
        
        // Block the app
        blockApp(app, name: appName)
    }

    func startMonitoring(with resources: [Resource]) {
        // Build allowed apps set from resources
        allowedApps = Set(resources.filter { $0.type == .application }.map { $0.name })
        allowedApps.formUnion(systemApps)
        
        // Also add TimeTasker by bundle ID check
        allowedApps.insert("TimeTasker")
        allowedApps.insert("Time Tasker")
        
        isMonitoring = true
        
        print("✅ Monitoring started")
        print("📋 Allowed apps: \(allowedApps.sorted().joined(separator: ", "))")
    }

    func stopMonitoring() {
        isMonitoring = false
        allowedApps.removeAll()
        blockedAppName = ""
        print("⛔ Monitoring stopped")
    }

    private func blockApp(_ app: NSRunningApplication, name: String) {
        print("🚫 BLOCKING app: \(name)")
        blockedAppName = name
        
        // Show alert on main thread
        DispatchQueue.main.async { [weak self] in
            self?.showBlockedAlert(appName: name)
        }
        
        // Terminate the app
        let terminated = app.terminate()
        if !terminated {
            // Force terminate if normal terminate fails
            app.forceTerminate()
        }
        
        // Bring Time Tasker to front
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            
            // Find and activate our window
            if let window = NSApp.windows.first(where: { $0.isVisible }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    private func showBlockedAlert(appName: String) {
        let alert = NSAlert()
        alert.messageText = "🚫 App Blocked"
        alert.informativeText = "\"\(appName)\" is not allowed during this focus session.\n\nOnly apps in your task's allowed list can be used."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        // Play alert sound
        NSSound.beep()
        
        alert.runModal()
    }

    deinit {
        if let observer = notificationObserver {
            workspace.notificationCenter.removeObserver(observer)
        }
    }
}
