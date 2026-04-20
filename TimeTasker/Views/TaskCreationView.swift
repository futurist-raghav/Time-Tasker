import SwiftUI
import AppKit

// Task templates for quick creation
struct TaskTemplate: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: Category
    let duration: TimeInterval  // in seconds
    let description: String
}

let taskTemplates: [TaskTemplate] = [
    TaskTemplate(name: "Quick Focus", icon: "bolt.fill", category: .coding, duration: 25 * 60, description: "25 min focus session"),
    TaskTemplate(name: "Deep Work", icon: "brain.head.profile", category: .coding, duration: 90 * 60, description: "90 min deep work"),
    TaskTemplate(name: "Writing Sprint", icon: "pencil.line", category: .writing, duration: 30 * 60, description: "30 min writing"),
    TaskTemplate(name: "Design Session", icon: "paintbrush.fill", category: .design, duration: 60 * 60, description: "1 hour design"),
    TaskTemplate(name: "Research Block", icon: "book.fill", category: .research, duration: 45 * 60, description: "45 min research"),
    TaskTemplate(name: "Pomodoro", icon: "timer", category: .coding, duration: 25 * 60, description: "Classic 25 min pomodoro"),
]

struct TaskCreationView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var selectedCategory: Category = .coding
    @State private var deadline = Date().addingTimeInterval(3600)
    @State private var selectedResources: [Resource] = []
    @State private var websiteInput = ""
    @State private var showAppPicker = false
    @State private var showTemplates = true
    @State private var naturalDeadlineInput = ""
    @State private var naturalDeadlineFeedback: String?
    @State private var isPomodoroMode = false
    @State private var pomodoroWorkMinutes = 25
    @State private var pomodoroBreakMinutes = 5
    @State private var pomodoroLongBreakMinutes = 15
    @State private var pomodoroSessionsBeforeLongBreak = 4
    @State private var estimatedMinutes = 60
    @State private var priority: TaskPriority = .medium
    @State private var notes = ""
    @State private var showBlockedResources = true
    
    private var blockedApps: [Resource] {
        selectedResources.filter { $0.type == .application }
    }
    
    private var blockedWebsites: [Resource] {
        selectedResources.filter { $0.type == .website }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DisclosureGroup("Use a Template", isExpanded: $showTemplates) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(taskTemplates) { template in
                                    TemplateButton(template: template) {
                                        applyTemplate(template)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Quick Templates")
                } footer: {
                    Text("Start with a preset, then fine-tune title, timing, and focus behavior.")
                }

                Section("Header") {
                    TextField("Task title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .accessibilityIdentifier("taskCreation.titleField")

                    HStack(spacing: 12) {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Label(category.rawValue, systemImage: category.iconName)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { level in
                                Label(level.rawValue, systemImage: level.iconName)
                                    .tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .onChange(of: selectedCategory) { _, newCategory in
                        applyDefaultAppsIfNeeded(for: newCategory)
                    }

                    TextField("Natural deadline (e.g. today 5pm, tomorrow 9am, in 2h)", text: $naturalDeadlineInput)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 10) {
                        Button("Apply Deadline") {
                            applyNaturalDeadlineInput()
                        }
                        .buttonStyle(.bordered)
                        .disabled(naturalDeadlineInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if let naturalDeadlineFeedback {
                            Text(naturalDeadlineFeedback)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Deadline")
                            .font(.subheadline.weight(.medium))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                deadlineShortcutButton("+30m") {
                                    deadline = Date().addingTimeInterval(30 * 60)
                                }
                                deadlineShortcutButton("+1h") {
                                    deadline = Date().addingTimeInterval(60 * 60)
                                }
                                deadlineShortcutButton("+2h") {
                                    deadline = Date().addingTimeInterval(2 * 60 * 60)
                                }
                                deadlineShortcutButton("Tonight") {
                                    setDeadlineTodayAt(hour: 20)
                                }
                                deadlineShortcutButton("Tomorrow 9AM") {
                                    setDeadlineTomorrowAt(hour: 9)
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        HStack(spacing: 12) {
                            DatePicker(
                                "Date",
                                selection: $deadline,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)

                            DatePicker(
                                "Time",
                                selection: $deadline,
                                in: Date()...,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                        }
                    }
                }

                Section("Focus Behavior") {
                    Toggle(isOn: $isPomodoroMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Pomodoro", systemImage: "timer")
                            Text("\(pomodoroWorkMinutes)m focus / \(pomodoroBreakMinutes)m break")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: isPomodoroMode) { _, newValue in
                        if newValue {
                            deadline = Date().addingTimeInterval(TimeInterval(pomodoroWorkMinutes * 60))
                        }
                    }

                    if isPomodoroMode {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Work Duration")
                                Spacer()
                                Stepper(value: $pomodoroWorkMinutes, in: 10...180, step: 5) {
                                    Text("\(pomodoroWorkMinutes) min")
                                        .monospacedDigit()
                                }
                                .frame(maxWidth: 160)
                            }

                            HStack {
                                Text("Short Break")
                                Spacer()
                                Stepper(value: $pomodoroBreakMinutes, in: 5...60, step: 5) {
                                    Text("\(pomodoroBreakMinutes) min")
                                        .monospacedDigit()
                                }
                                .frame(maxWidth: 160)
                            }

                            HStack {
                                Text("Long Break")
                                Spacer()
                                Stepper(value: $pomodoroLongBreakMinutes, in: 10...90, step: 5) {
                                    Text("\(pomodoroLongBreakMinutes) min")
                                        .monospacedDigit()
                                }
                                .frame(maxWidth: 160)
                            }

                            HStack {
                                Text("Sessions Before Long Break")
                                Spacer()
                                Stepper(value: $pomodoroSessionsBeforeLongBreak, in: 2...8) {
                                    Text("\(pomodoroSessionsBeforeLongBreak)")
                                        .monospacedDigit()
                                }
                                .frame(maxWidth: 160)
                            }
                        }
                        .font(.subheadline)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Blocking Profile", systemImage: "shield.lefthalf.filled")
                            .font(.subheadline.weight(.semibold))
                        Text("\(blockedApps.count) apps and \(blockedWebsites.count) websites currently selected.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    DisclosureGroup("Manage blocked resources", isExpanded: $showBlockedResources) {
                        HStack(spacing: 8) {
                            Button("Use Category Defaults") {
                                replaceCategoryDefaultApps(for: selectedCategory)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button("Clear All") {
                                clearBlockedResources()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(selectedResources.isEmpty)

                            Spacer(minLength: 0)
                        }

                        if blockedApps.isEmpty {
                            Text("No blocked apps selected")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(blockedApps) { resource in
                                HStack {
                                    if let icon = getAppIcon(for: resource.path) {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                    } else {
                                        Image(systemName: "app.fill")
                                            .frame(width: 20, height: 20)
                                    }
                                    Text(resource.name)
                                        .lineLimit(1)

                                    Spacer()

                                    Button(action: {
                                        removeResource(resource)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Button(action: { showAppPicker = true }) {
                            Label("Add Blocked Apps", systemImage: "plus.circle.fill")
                        }

                        HStack(spacing: 8) {
                            TextField("youtube.com", text: $websiteInput)
                                .textFieldStyle(.roundedBorder)

                            Button("Add") {
                                addWebsiteFromInput()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(normalizeDomain(websiteInput) == nil)
                        }

                        if blockedWebsites.isEmpty {
                            Text("No blocked websites selected")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(blockedWebsites) { website in
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.secondary)
                                    Text(website.name)
                                        .lineLimit(1)

                                    Spacer()

                                    Button(action: {
                                        removeResource(website)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Section("Notes & Metadata") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .font(.body)

                    Stepper(value: $estimatedMinutes, in: 15...480, step: 15) {
                        HStack {
                            Text("Estimated Duration")
                            Spacer()
                            Text("\(estimatedMinutes) min")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .accessibilityIdentifier("taskCreation.form")
            .navigationTitle("Create Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Task") {
                        createTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showAppPicker) {
                AppPickerView(selectedResources: $selectedResources)
                    .frame(minWidth: 400, minHeight: 500)
            }
        }
        .frame(minWidth: 620, minHeight: 700)
        .onAppear {
            applyDefaultAppsIfNeeded(for: selectedCategory)
        }
        .onChange(of: pomodoroWorkMinutes) { _, newValue in
            if isPomodoroMode {
                deadline = Date().addingTimeInterval(TimeInterval(newValue * 60))
            }
        }
    }
    
    private func getAppIcon(for path: String) -> NSImage? {
        let workspace = NSWorkspace.shared
        if FileManager.default.fileExists(atPath: path) {
            return workspace.icon(forFile: path)
        }
        return nil
    }

    private func defaultAppResources(for category: Category) -> [Resource] {
        category.defaultBlockedApps.compactMap { appName in
            // Try to find the actual app path
            let possiblePaths = [
                "/Applications/\(appName).app",
                "/System/Applications/\(appName).app",
                "/System/Applications/Utilities/\(appName).app",
                "\(NSHomeDirectory())/Applications/\(appName).app"
            ]
            
            for path in possiblePaths {
                if FileManager.default.fileExists(atPath: path) {
                    return Resource(name: appName, path: path, type: .application)
                }
            }
            
            // Return with default path even if not found (user might have it elsewhere)
            return Resource(name: appName, path: "/Applications/\(appName).app", type: .application)
        }
    }

    private func applyDefaultAppsIfNeeded(for category: Category) {
        let hasAppRules = selectedResources.contains { $0.type == .application }
        guard !hasAppRules else { return }

        let websiteRules = selectedResources.filter { $0.type == .website }
        selectedResources = defaultAppResources(for: category) + websiteRules
    }

    private func replaceCategoryDefaultApps(for category: Category) {
        let websiteRules = selectedResources.filter { $0.type == .website }
        selectedResources = defaultAppResources(for: category) + websiteRules
    }

    private func clearBlockedResources() {
        selectedResources.removeAll()
    }
    
    private func applyTemplate(_ template: TaskTemplate) {
        title = template.name
        selectedCategory = template.category
        isPomodoroMode = template.name == "Pomodoro"
        deadline = Date().addingTimeInterval(isPomodoroMode ? TimeInterval(pomodoroWorkMinutes * 60) : template.duration)
        estimatedMinutes = max(15, Int(template.duration / 60))
        replaceCategoryDefaultApps(for: template.category)
        showTemplates = false  // Collapse templates after selection
    }

    private func createTask() {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else { return }

        let task = Task(
            title: normalizedTitle,
            deadline: deadline,
            category: selectedCategory,
            resources: selectedResources,
            isPomodoroMode: isPomodoroMode,
            notes: notes,
            priority: priority,
            estimatedDuration: TimeInterval(estimatedMinutes * 60),
            pomodoroWorkDuration: TimeInterval(pomodoroWorkMinutes * 60),
            pomodoroBreakDuration: TimeInterval(pomodoroBreakMinutes * 60),
            pomodoroLongBreakDuration: TimeInterval(pomodoroLongBreakMinutes * 60),
            pomodoroSessionsBeforeLongBreak: pomodoroSessionsBeforeLongBreak
        )
        viewModel.addTask(task)
        dismiss()
    }

    private func deadlineShortcutButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.small)
    }

    private func setDeadlineTodayAt(hour: Int) {
        let calendar = Calendar.current
        let now = Date()
        let targetToday = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
        if targetToday > now {
            deadline = targetToday
        } else {
            deadline = calendar.date(byAdding: .day, value: 1, to: targetToday) ?? now.addingTimeInterval(24 * 60 * 60)
        }
    }

    private func setDeadlineTomorrowAt(hour: Int) {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(24 * 60 * 60)
        deadline = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    private func applyNaturalDeadlineInput() {
        guard let parsedDate = parseNaturalDeadline(naturalDeadlineInput) else {
            naturalDeadlineFeedback = "Could not parse that date. Try: today 5pm, tomorrow 9am, or in 2h"
            return
        }

        guard parsedDate >= Date() else {
            naturalDeadlineFeedback = "Parsed time is in the past. Try a future time."
            return
        }

        deadline = parsedDate

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        naturalDeadlineFeedback = "Deadline set to \(formatter.string(from: parsedDate))"
    }

    private func parseNaturalDeadline(_ input: String) -> Date? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lower = trimmed.lowercased()
        let calendar = Calendar.current
        let now = Date()

        if lower == "today" {
            return setDate(base: now, timeFragment: "6pm")
        }

        if lower == "tomorrow" {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            return setDate(base: tomorrow, timeFragment: "9am")
        }

        if lower.hasPrefix("in ") {
            let value = lower.dropFirst(3)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let parsed = parseRelativeDuration(value, from: now) {
                return parsed
            }
        }

        if lower.hasPrefix("today ") {
            let fragment = String(lower.dropFirst("today ".count))
            return setDate(base: now, timeFragment: fragment)
        }

        if lower.hasPrefix("tomorrow ") {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            let fragment = String(lower.dropFirst("tomorrow ".count))
            return setDate(base: tomorrow, timeFragment: fragment)
        }

        if let absolute = parseAbsoluteDateTime(trimmed) {
            return absolute
        }

        return nil
    }

    private func parseRelativeDuration(_ value: String, from reference: Date) -> Date? {
        let compact = value.replacingOccurrences(of: " ", with: "")

        if compact.hasSuffix("min"), let minutes = Int(compact.dropLast(3)) {
            return reference.addingTimeInterval(TimeInterval(minutes * 60))
        }

        if compact.hasSuffix("m"), let minutes = Int(compact.dropLast()) {
            return reference.addingTimeInterval(TimeInterval(minutes * 60))
        }

        if compact.hasSuffix("h"), let hours = Int(compact.dropLast()) {
            return reference.addingTimeInterval(TimeInterval(hours * 3600))
        }

        if compact.hasSuffix("d"), let days = Int(compact.dropLast()) {
            return reference.addingTimeInterval(TimeInterval(days * 86400))
        }

        return nil
    }

    private func setDate(base: Date, timeFragment: String) -> Date? {
        let calendar = Calendar.current
        let normalized = timeFragment
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let formats = ["h:mma", "hha", "ha", "h a", "h:mm a", "H:mm", "H"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in formats {
            formatter.dateFormat = format
            if let parsedTime = formatter.date(from: normalized) {
                let components = calendar.dateComponents([.hour, .minute], from: parsedTime)
                return calendar.date(
                    bySettingHour: components.hour ?? 9,
                    minute: components.minute ?? 0,
                    second: 0,
                    of: base
                )
            }
        }

        return nil
    }

    private func parseAbsoluteDateTime(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current

        let formats = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd h:mma",
            "MMM d h:mma",
            "MMM d H:mm"
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }
    
    private func addWebsiteFromInput() {
        guard let normalized = normalizeDomain(websiteInput) else { return }
        let isDuplicate = selectedResources.contains { resource in
            resource.type == .website && resource.path.lowercased() == normalized
        }
        guard !isDuplicate else {
            websiteInput = ""
            return
        }
        
        selectedResources.append(Resource(name: normalized, path: normalized, type: .website))
        websiteInput = ""
    }
    
    private func normalizeDomain(_ value: String) -> String? {
        var candidate = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !candidate.isEmpty else { return nil }
        
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
    
    private func removeResource(_ resource: Resource) {
        selectedResources.removeAll { $0.id == resource.id }
    }
}

// Template button component
struct TemplateButton: View {
    let template: TaskTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text(template.name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)

                    Text(template.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentSurface(cornerRadius: 10, tint: .accentColor, emphasis: 0.08)
        }
        .buttonStyle(.plain)
    }
}

struct AppPickerView: View {
    @Binding var selectedResources: [Resource]
    @Environment(\.dismiss) var dismiss

    @State private var availableApps: [AppInfo] = []
    @State private var searchText = ""
    @State private var isLoading = true
    
    private var selectedAppsCount: Int {
        selectedResources.filter { $0.type == .application }.count
    }

    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return availableApps
        }
        return availableApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search apps...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .contentSurface(cornerRadius: 10, tint: .secondary, emphasis: 0.04)
                .padding()

                Divider()

                if isLoading {
                    Spacer()
                    ProgressView("Loading applications...")
                    Spacer()
                } else if filteredApps.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "app.badge.questionmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No apps found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(filteredApps, id: \.path) { app in
                                AppRowView(
                                    app: app,
                                    isSelected: selectedResources.contains { $0.type == .application && $0.path == app.path },
                                    onTap: { toggleApp(app) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Select Blocked Apps (\(selectedAppsCount) selected)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            loadInstalledApps()
        }
    }
    
    private func toggleApp(_ app: AppInfo) {
        if let index = selectedResources.firstIndex(where: { $0.type == .application && $0.path == app.path }) {
            selectedResources.remove(at: index)
        } else {
            let resource = Resource(name: app.name, path: app.path, type: .application)
            selectedResources.append(resource)
        }
    }

    private func loadInstalledApps() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var apps: [AppInfo] = []
            let fileManager = FileManager.default
            let workspace = NSWorkspace.shared
            
            // Folders to search for apps
            let appFolders = [
                "/Applications",
                "/System/Applications",
                "/System/Applications/Utilities",
                "\(NSHomeDirectory())/Applications"
            ]
            
            for folder in appFolders {
                guard let contents = try? fileManager.contentsOfDirectory(atPath: folder) else { continue }
                
                for item in contents where item.hasSuffix(".app") {
                    let appPath = "\(folder)/\(item)"
                    let appName = item.replacingOccurrences(of: ".app", with: "")
                    
                    // Get app icon
                    let icon = workspace.icon(forFile: appPath)
                    
                    // Avoid duplicates
                    if !apps.contains(where: { $0.name == appName }) {
                        apps.append(AppInfo(name: appName, path: appPath, icon: icon))
                    }
                }
            }
            
            // Sort alphabetically
            apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.availableApps = apps
                self.isLoading = false
                print("✅ Loaded \(apps.count) applications")
            }
        }
    }
}

struct AppInfo {
    let name: String
    let path: String
    let icon: NSImage
}

struct AppRowView: View {
    let app: AppInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 32, height: 32)
                
                Text(app.name)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentSurface(
                cornerRadius: 8,
                tint: isSelected ? .green : .secondary,
                emphasis: isSelected ? 0.16 : 0.04,
                strokeOpacity: isSelected ? 0.95 : 0.7,
                shadowOpacity: 0.08
            )
        }
        .buttonStyle(.plain)
    }
}

struct TaskCreationView_Previews: PreviewProvider {
    static var previews: some View {
        TaskCreationView(viewModel: TaskListViewModel())
    }
}
