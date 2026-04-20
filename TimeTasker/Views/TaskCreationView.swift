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
    @State private var isPomodoroMode = false
    @State private var priority: TaskPriority = .medium
    @State private var notes = ""
    
    private var blockedApps: [Resource] {
        selectedResources.filter { $0.type == .application }
    }
    
    private var blockedWebsites: [Resource] {
        selectedResources.filter { $0.type == .website }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Quick Templates Section
                Section {
                    DisclosureGroup("Quick Templates", isExpanded: $showTemplates) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10) {
                            ForEach(taskTemplates) { template in
                                TemplateButton(template: template) {
                                    applyTemplate(template)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)

                    DatePicker("Deadline", selection: $deadline, in: Date()...)
                        .datePickerStyle(.compact)
                    
                    // Priority Picker
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { level in
                            HStack {
                                Image(systemName: level.iconName)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Pomodoro Mode Toggle
                    Toggle(isOn: $isPomodoroMode) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Pomodoro Mode")
                                Text("25 min work / 5 min break cycles")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: isPomodoroMode) { _, newValue in
                        if newValue {
                            deadline = Date().addingTimeInterval(25 * 60)
                        }
                    }
                }
                
                // Notes Section
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                        .font(.body)
                }

                Section("Category") {
                    Picker("Select Category", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: selectedCategory) { _, newCategory in
                        loadDefaultApps(for: newCategory)
                    }
                }

                Section("Blocked Apps (\\(blockedApps.count))") {
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
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Blocked Apps")
                        }
                    }
                }
                
                Section("Blocked Websites (\\(blockedWebsites.count))") {
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
            .formStyle(.grouped)
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
                    .disabled(title.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showAppPicker) {
                AppPickerView(selectedResources: $selectedResources)
                    .frame(minWidth: 400, minHeight: 500)
            }
        }
        .frame(minWidth: 450, minHeight: 550)
        .onAppear {
            loadDefaultApps(for: selectedCategory)
        }
    }
    
    private func getAppIcon(for path: String) -> NSImage? {
        let workspace = NSWorkspace.shared
        if FileManager.default.fileExists(atPath: path) {
            return workspace.icon(forFile: path)
        }
        return nil
    }

    private func loadDefaultApps(for category: Category) {
        let websiteRules = selectedResources.filter { $0.type == .website }
        let appRules = category.defaultBlockedApps.compactMap { appName in
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
        
        selectedResources = appRules + websiteRules
    }
    
    private func applyTemplate(_ template: TaskTemplate) {
        title = template.name
        selectedCategory = template.category
        deadline = Date().addingTimeInterval(template.duration)
        loadDefaultApps(for: template.category)
        showTemplates = false  // Collapse templates after selection
    }

    private func createTask() {
        let task = Task(
            title: title,
            deadline: deadline,
            category: selectedCategory,
            resources: selectedResources,
            isPomodoroMode: isPomodoroMode,
            notes: notes,
            priority: priority
        )
        viewModel.addTask(task)
        dismiss()
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
            VStack(spacing: 6) {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(template.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(template.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .liquidGlassCard(cornerRadius: 10, tint: .accentColor, tintOpacity: 0.15, strokeOpacity: 0.55, shadowOpacity: 0.08)
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
                .liquidGlassCard(cornerRadius: 10, tint: .white, tintOpacity: 0.08, strokeOpacity: 0.5, shadowOpacity: 0.06)
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
                                    isSelected: selectedResources.contains { $0.type == .application && $0.name == app.name },
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
        if let index = selectedResources.firstIndex(where: { $0.type == .application && $0.name == app.name }) {
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
            .liquidGlassCard(
                cornerRadius: 8,
                tint: isSelected ? .green : .white,
                tintOpacity: isSelected ? 0.16 : 0.06,
                strokeOpacity: isSelected ? 0.7 : 0.4,
                shadowOpacity: 0.06
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
