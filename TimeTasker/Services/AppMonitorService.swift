import Foundation
import AppKit
import Combine

enum WebsiteEnforcementMode: String {
    case inactive
    case browserFallback
    case systemWide

    var label: String {
        switch self {
        case .inactive:
            return "Website enforcement idle"
        case .browserFallback:
            return "Website blocking: Browser-level fallback"
        case .systemWide:
            return "Website blocking: System-wide (/etc/hosts)"
        }
    }
}

class AppMonitorService: ObservableObject {
    static let shared = AppMonitorService()

    private enum SettingsKeys {
        static let blockingEnabled = "blockingEnabled"
        static let soundEnabled = "soundEnabled"
        static let enableSystemWideHostsBlocking = "enableSystemWideHostsBlocking"
    }

    @Published var blockedApps: Set<String> = []
    @Published var blockedWebsites: Set<String> = []
    @Published var blockedAppName: String = ""
    @Published var blockedWebsite: String = ""
    @Published var websiteEnforcementMode: WebsiteEnforcementMode = .inactive
    @Published var isMonitoring = false
    
    private let workspace = NSWorkspace.shared
    private var notificationObserver: Any?
    private var websiteMonitorTimer: Timer?
    private var blockedBundleIDs: Set<String> = []
    private var lastWebsiteViolation: (domain: String, at: Date)?
    private var hostsRulesInstalled = false
    private let hostsBlocker = HostsFileBlocker()

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
    
    private let knownBrowserBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "com.microsoft.edgemac",
        "com.brave.Browser",
        "com.vivaldi.Vivaldi",
        "com.operasoftware.Opera",
        "company.thebrowser.Browser",
        "com.comet.browser"
    ]
    
    private let browserScriptNamesByBundleID: [String: String] = [
        "com.apple.Safari": "Safari",
        "com.google.Chrome": "Google Chrome",
        "org.mozilla.firefox": "Firefox",
        "com.microsoft.edgemac": "Microsoft Edge",
        "com.brave.Browser": "Brave Browser",
        "com.vivaldi.Vivaldi": "Vivaldi",
        "com.operasoftware.Opera": "Opera",
        "company.thebrowser.Browser": "Arc",
        "com.comet.browser": "Comet"
    ]
    
    private let browserNameFallbacks: [String: String] = [
        "safari": "Safari",
        "google chrome": "Google Chrome",
        "chrome": "Google Chrome",
        "chromium": "Google Chrome",
        "firefox": "Firefox",
        "microsoft edge": "Microsoft Edge",
        "brave browser": "Brave Browser",
        "vivaldi": "Vivaldi",
        "opera": "Opera",
        "arc": "Arc",
        "comet": "Comet"
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
            self?.checkAndEnforceRules(app: app, appName: appName, bundleID: bundleID)
        }
    }
    
    private func checkAndEnforceRules(app: NSRunningApplication, appName: String, bundleID: String) {
        guard isMonitoring else { return }
        
        if systemApps.contains(appName) {
            print("✅ System app allowed: \(appName)")
            return
        }
        
        if isAppBlocked(appName: appName, bundleID: bundleID) {
            blockApp(app, name: appName)
            return
        }
        
        if let blockedDomain = blockedDomainIfNeeded(for: appName, bundleID: bundleID) {
            blockWebsite(domain: blockedDomain, appName: appName, bundleID: bundleID)
        }
    }

    func startMonitoring(with resources: [Resource]) {
        guard isBlockingEnabled else {
            print("ℹ️ Blocking disabled in Settings; skipping enforcement")
            stopMonitoring()
            return
        }

        let appResources = resources.filter { $0.type == .application }
        let websiteResources = resources.filter { $0.type == .website }

        if hostsRulesInstalled {
            _ = hostsBlocker.clearManagedRules()
            hostsRulesInstalled = false
        }
        
        blockedApps = Set(appResources.map { $0.name })
        blockedBundleIDs = Set(appResources.compactMap { resource in
            Bundle(url: URL(fileURLWithPath: resource.path))?.bundleIdentifier?.lowercased()
        })
        blockedWebsites = Set(websiteResources.compactMap { resource in
            normalizeDomain(resource.path.isEmpty ? resource.name : resource.path)
        })
        blockedAppName = ""
        blockedWebsite = ""
        lastWebsiteViolation = nil
        websiteEnforcementMode = .inactive
        
        isMonitoring = true
        startWebsiteMonitorTimer()
        
        if !blockedWebsites.isEmpty {
            if isSystemWideHostsBlockingEnabled {
                let hostsUpdateSucceeded = hostsBlocker.applyBlockedDomains(blockedWebsites)
                hostsRulesInstalled = hostsUpdateSucceeded

                if hostsUpdateSucceeded {
                    websiteEnforcementMode = .systemWide
                    print("🌐 System-wide website blocking enabled for \(blockedWebsites.count) domain(s)")
                } else {
                    websiteEnforcementMode = .browserFallback
                    print("⚠️ Could not update /etc/hosts; browser-tab fallback will still run")
                }
            } else {
                websiteEnforcementMode = .browserFallback
                print("ℹ️ Using browser-level website blocking only (system-wide hosts blocking is disabled)")
            }
        }
        
        print("✅ Monitoring started")
        print("🚫 Blocked apps: \(blockedApps.sorted().joined(separator: ", "))")
        print("🌐 Blocked websites: \(blockedWebsites.sorted().joined(separator: ", "))")
    }

    func stopMonitoring() {
        isMonitoring = false
        blockedApps.removeAll()
        blockedWebsites.removeAll()
        blockedBundleIDs.removeAll()
        blockedAppName = ""
        blockedWebsite = ""
        websiteEnforcementMode = .inactive
        lastWebsiteViolation = nil
        stopWebsiteMonitorTimer()

        if hostsRulesInstalled {
            _ = hostsBlocker.clearManagedRules()
            hostsRulesInstalled = false
        }

        print("⛔ Monitoring stopped")
    }

    private var isSystemWideHostsBlockingEnabled: Bool {
        if let storedValue = UserDefaults.standard.object(forKey: SettingsKeys.enableSystemWideHostsBlocking) as? Bool {
            return storedValue
        }
        return true
    }

    private var isBlockingEnabled: Bool {
        if let storedValue = UserDefaults.standard.object(forKey: SettingsKeys.blockingEnabled) as? Bool {
            return storedValue
        }
        return true
    }

    private var isAlertSoundEnabled: Bool {
        if let storedValue = UserDefaults.standard.object(forKey: SettingsKeys.soundEnabled) as? Bool {
            return storedValue
        }
        return true
    }
    
    private func startWebsiteMonitorTimer() {
        stopWebsiteMonitorTimer()
        websiteMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollFrontmostAppForViolations()
        }
        RunLoop.main.add(websiteMonitorTimer!, forMode: .common)
    }
    
    private func stopWebsiteMonitorTimer() {
        websiteMonitorTimer?.invalidate()
        websiteMonitorTimer = nil
    }
    
    private func pollFrontmostAppForViolations() {
        guard isMonitoring else { return }
        guard let frontmost = workspace.frontmostApplication else { return }
        
        let appName = frontmost.localizedName ?? frontmost.bundleIdentifier ?? "Unknown"
        let bundleID = frontmost.bundleIdentifier ?? ""
        
        if systemApps.contains(appName) {
            return
        }
        
        if isAppBlocked(appName: appName, bundleID: bundleID) {
            blockApp(frontmost, name: appName)
            return
        }
        
        if let blockedDomain = blockedDomainIfNeeded(for: appName, bundleID: bundleID) {
            blockWebsite(domain: blockedDomain, appName: appName, bundleID: bundleID)
        }
    }
    
    private func isAppBlocked(appName: String, bundleID: String) -> Bool {
        let appNameLower = appName.lowercased()
        let bundleIDLower = bundleID.lowercased()
        
        if blockedBundleIDs.contains(bundleIDLower) {
            return true
        }
        
        return blockedApps.contains { blocked in
            let blockedLower = blocked.lowercased()
            if appNameLower == blockedLower || appNameLower.contains(blockedLower) || blockedLower.contains(appNameLower) {
                return true
            }
            
            if !bundleIDLower.isEmpty {
                let token = blockedLower.replacingOccurrences(of: " ", with: "")
                return bundleIDLower.contains(token)
            }
            
            return false
        }
    }
    
    private func blockedDomainIfNeeded(for appName: String, bundleID: String) -> String? {
        guard !blockedWebsites.isEmpty else { return nil }
        guard isBrowser(appName: appName, bundleID: bundleID) else { return nil }
        guard let currentURL = activeBrowserURL(for: appName, bundleID: bundleID) else { return nil }
        guard let host = extractHost(from: currentURL) else { return nil }
        
        let hostLower = host.lowercased()
        return blockedWebsites.first(where: { blocked in
            hostLower == blocked || hostLower.hasSuffix(".\(blocked)")
        })
    }
    
    private func isBrowser(appName: String, bundleID: String) -> Bool {
        if knownBrowserBundleIDs.contains(bundleID) {
            return true
        }
        
        let appNameLower = appName.lowercased()
        return browserNameFallbacks.keys.contains(where: { appNameLower.contains($0) })
    }
    
    private func activeBrowserURL(for appName: String, bundleID: String) -> String? {
        guard let scriptName = browserScriptName(for: appName, bundleID: bundleID) else {
            return nil
        }
        
        let script: String
        if scriptName == "Safari" {
            script = "tell application \"Safari\" to if (count of windows) > 0 then return URL of current tab of front window"
        } else if scriptName == "Firefox" {
            script = "tell application \"Firefox\" to if (count of windows) > 0 then return URL of front window"
        } else {
            script = "tell application \"\(scriptName)\" to if (count of windows) > 0 then return URL of active tab of front window"
        }
        
        return runAppleScript(script)
    }
    
    private func browserScriptName(for appName: String, bundleID: String) -> String? {
        if let mapped = browserScriptNamesByBundleID[bundleID] {
            return mapped
        }
        
        let appNameLower = appName.lowercased()
        return browserNameFallbacks.first(where: { appNameLower.contains($0.key) })?.value
    }
    
    private func runAppleScript(_ script: String) -> String? {
        guard let appleScript = NSAppleScript(source: script) else {
            return nil
        }
        
        var errorInfo: NSDictionary?
        let response = appleScript.executeAndReturnError(&errorInfo)
        
        if let errorInfo {
            print("⚠️ AppleScript error: \(errorInfo)")
            return nil
        }
        
        return response.stringValue
    }
    
    private func blockWebsite(domain: String, appName: String, bundleID: String) {
        if let lastViolation = lastWebsiteViolation,
           lastViolation.domain == domain,
           Date().timeIntervalSince(lastViolation.at) < 4 {
            bringTimeTaskerToFront()
            return
        }
        
        lastWebsiteViolation = (domain, Date())
        blockedWebsite = domain
        print("🚫 BLOCKING website: \(domain)")
        
        redirectFrontTabToBlank(for: appName, bundleID: bundleID)
        
        DispatchQueue.main.async { [weak self] in
            self?.showBlockedWebsiteAlert(domain: domain)
        }
        
        bringTimeTaskerToFront()
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

        bringTimeTaskerToFront()
    }
    
    private func redirectFrontTabToBlank(for appName: String, bundleID: String) {
        guard let scriptName = browserScriptName(for: appName, bundleID: bundleID) else {
            return
        }
        
        let script: String
        if scriptName == "Safari" {
            script = "tell application \"Safari\" to if (count of windows) > 0 then set URL of current tab of front window to \"about:blank\""
        } else if scriptName == "Firefox" {
            script = "tell application \"Firefox\" to if (count of windows) > 0 then set URL of front window to \"about:blank\""
        } else {
            script = "tell application \"\(scriptName)\" to if (count of windows) > 0 then set URL of active tab of front window to \"about:blank\""
        }
        
        _ = runAppleScript(script)
    }
    
    private func bringTimeTaskerToFront() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: { $0.isVisible }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    private func showBlockedAlert(appName: String) {
        let alert = NSAlert()
        alert.messageText = "🚫 App Blocked"
        alert.informativeText = "\"\(appName)\" is blocked during this focus session.\n\nRemove it from your task's blocked list to use it again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        if isAlertSoundEnabled {
            NSSound.beep()
        }
        
        alert.runModal()
    }
    
    private func showBlockedWebsiteAlert(domain: String) {
        let alert = NSAlert()
        alert.messageText = "🌐 Website Blocked"
        alert.informativeText = "\"\(domain)\" is blocked during this focus session.\n\nRemove it from your task's blocked websites to access it again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        if isAlertSoundEnabled {
            NSSound.beep()
        }
        alert.runModal()
    }
    
    private func extractHost(from rawURL: String) -> String? {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if let host = URLComponents(string: trimmed)?.host {
            return normalizeDomain(host)
        }
        
        return normalizeDomain(trimmed)
    }
    
    private func normalizeDomain(_ value: String) -> String? {
        var candidate = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        if candidate.isEmpty {
            return nil
        }
        
        if !candidate.contains("://") {
            candidate = "https://\(candidate)"
        }
        
        guard var host = URLComponents(string: candidate)?.host?.lowercased() else {
            return nil
        }
        
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        
        return host.isEmpty ? nil : host
    }

    deinit {
        stopWebsiteMonitorTimer()
        if hostsRulesInstalled {
            _ = hostsBlocker.clearManagedRules()
        }
        if let observer = notificationObserver {
            workspace.notificationCenter.removeObserver(observer)
        }
    }
}

private final class HostsFileBlocker {
    private let hostsPath = "/etc/hosts"
    private let markerStart = "# TimeTasker Focus Block START"
    private let markerEnd = "# TimeTasker Focus Block END"
    
    func applyBlockedDomains(_ domains: Set<String>) -> Bool {
        guard !domains.isEmpty else {
            return clearManagedRules()
        }
        
        guard let existing = try? String(contentsOfFile: hostsPath, encoding: .utf8) else {
            print("⚠️ Unable to read /etc/hosts")
            return false
        }
        
        let cleaned = removeManagedRules(from: existing).trimmingCharacters(in: .whitespacesAndNewlines)
        let rules = buildRulesBlock(for: domains)
        let merged = [cleaned, rules]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n") + "\n"
        
        return writeHostsContents(merged)
    }
    
    func clearManagedRules() -> Bool {
        guard let existing = try? String(contentsOfFile: hostsPath, encoding: .utf8) else {
            return false
        }
        
        let cleaned = removeManagedRules(from: existing)
        guard cleaned != existing else {
            return true
        }
        
        return writeHostsContents(cleaned)
    }
    
    private func buildRulesBlock(for domains: Set<String>) -> String {
        var lines: [String] = [markerStart]
        
        for domain in domains.sorted() {
            lines.append("127.0.0.1 \(domain)")
            lines.append("127.0.0.1 www.\(domain)")
            lines.append("::1 \(domain)")
            lines.append("::1 www.\(domain)")
        }
        
        lines.append(markerEnd)
        return lines.joined(separator: "\n")
    }
    
    private func removeManagedRules(from contents: String) -> String {
        guard let startRange = contents.range(of: markerStart),
              let endRange = contents.range(of: markerEnd, range: startRange.upperBound..<contents.endIndex) else {
            return contents
        }
        
        var mutable = contents
        mutable.removeSubrange(startRange.lowerBound..<endRange.upperBound)
        
        while mutable.contains("\n\n\n") {
            mutable = mutable.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        return mutable.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }
    
    private func writeHostsContents(_ contents: String) -> Bool {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("timetasker-hosts-\(UUID().uuidString).tmp")
        
        do {
            try contents.write(to: tempURL, atomically: true, encoding: .utf8)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            let copyCommand = [
                "cp \(shellEscape(tempURL.path)) \(shellEscape(hostsPath))",
                "dscacheutil -flushcache",
                "killall -HUP mDNSResponder"
            ].joined(separator: " && ")
            
            return runPrivilegedShell(copyCommand)
        } catch {
            print("⚠️ Failed to prepare hosts update: \(error)")
            return false
        }
    }
    
    private func runPrivilegedShell(_ command: String) -> Bool {
        let escaped = appleScriptEscape(command)
        let source = "do shell script \"\(escaped)\" with administrator privileges"
        
        guard let script = NSAppleScript(source: source) else {
            return false
        }
        
        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        
        if let errorInfo {
            print("⚠️ Privileged command failed: \(errorInfo)")
            return false
        }
        
        return true
    }
    
    private func shellEscape(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
    
    private func appleScriptEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
