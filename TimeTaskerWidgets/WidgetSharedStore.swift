import Foundation
import WidgetKit

enum WidgetSharedStorageConfiguration {
    static let appGroupIdentifier = "group.com.raghavagarwal.timetasker"
    static let fallbackSuiteIdentifier = "com.raghavagarwal.TimeTasker.shared"
}

enum WidgetSharedStorageKeys {
    static let tasks = "SavedTasksArray"
    static let taskHistory = "taskHistory"
    static let lastAnalyticsDate = "lastAnalyticsDate"
    static let totalFocusTimeToday = "totalFocusTimeToday"
    static let tasksCompletedToday = "tasksCompletedToday"
    static let currentStreak = "currentStreak"
    static let sharedMutationToken = "sharedMutationToken"

    static let pendingWidgetCommand = "widgetPendingCommand"
    static let pausedFocusTaskID = "widgetPausedFocusTaskID"
}

enum WidgetKindID {
    static let todayTasks = "TodayTasksWidget"
    static let focusSession = "FocusSessionWidget"
    static let quickAddStats = "QuickAddStatsWidget"
}

enum WidgetTaskStore {
    private static let defaults: UserDefaults = {
        if let shared = UserDefaults(suiteName: WidgetSharedStorageConfiguration.appGroupIdentifier) {
            return shared
        }

        if let shared = UserDefaults(suiteName: WidgetSharedStorageConfiguration.fallbackSuiteIdentifier) {
            return shared
        }

        return .standard
    }()

    private static var calendar: Calendar {
        .current
    }

    static func loadTasks() -> [WidgetTask] {
        guard let data = defaults.data(forKey: WidgetSharedStorageKeys.tasks) else {
            return []
        }

        do {
            return try PropertyListDecoder().decode([WidgetTask].self, from: data)
        } catch {
            print("Widget task decode failed: \(error)")
            return []
        }
    }

    static func loadTodayTasks(limit: Int) -> [WidgetTask] {
        loadTasks()
            .filter { task in
                task.isActive || !task.isExpired
            }
            .sorted { lhs, rhs in
                if lhs.isActive != rhs.isActive {
                    return lhs.isActive
                }

                if lhs.isExpired != rhs.isExpired {
                    return !lhs.isExpired
                }

                if lhs.priority != rhs.priority {
                    return lhs.priority.rank > rhs.priority.rank
                }

                return lhs.deadline < rhs.deadline
            }
            .prefix(limit)
            .map { $0 }
    }

    static func loadPendingTasks(limit: Int) -> [WidgetTask] {
        loadTasks()
            .filter { !$0.isActive && !$0.isExpired }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return lhs.priority.rank > rhs.priority.rank
                }

                return lhs.deadline < rhs.deadline
            }
            .prefix(limit)
            .map { $0 }
    }

    static func loadActiveTask() -> WidgetTask? {
        loadTasks().first(where: { $0.isActive })
    }

    static func loadPausedTask() -> WidgetTask? {
        guard let rawID = defaults.string(forKey: WidgetSharedStorageKeys.pausedFocusTaskID),
              let uuid = UUID(uuidString: rawID) else {
            return nil
        }

        return loadTasks().first(where: { $0.id == uuid })
    }

    static func loadDailyStats() -> WidgetDailyStats {
        let now = Date()
        let lastDate = defaults.object(forKey: WidgetSharedStorageKeys.lastAnalyticsDate) as? Date

        if let lastDate, calendar.isDate(lastDate, inSameDayAs: now) {
            return WidgetDailyStats(
                totalFocusTimeToday: defaults.double(forKey: WidgetSharedStorageKeys.totalFocusTimeToday),
                tasksCompletedToday: defaults.integer(forKey: WidgetSharedStorageKeys.tasksCompletedToday),
                currentStreak: defaults.integer(forKey: WidgetSharedStorageKeys.currentStreak)
            )
        }

        return WidgetDailyStats(
            totalFocusTimeToday: 0,
            tasksCompletedToday: 0,
            currentStreak: defaults.integer(forKey: WidgetSharedStorageKeys.currentStreak)
        )
    }

    static func completeTask(id: UUID) {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return
        }

        let task = tasks.remove(at: index)
        let focusTime = task.focusTimeSpent

        var history = loadHistory()
        let completed = WidgetCompletedTask(
            id: task.id,
            title: task.title,
            category: task.category,
            completedAt: Date(),
            focusTime: focusTime,
            originalDeadline: task.deadline,
            wasSuccessful: !task.isExpired
        )
        history.insert(completed, at: 0)

        var stats = loadDailyStats()
        stats.totalFocusTimeToday += focusTime
        stats.tasksCompletedToday += 1
        stats.currentStreak = computeCurrentStreak(from: history)

        if defaults.string(forKey: WidgetSharedStorageKeys.pausedFocusTaskID) == task.id.uuidString {
            defaults.removeObject(forKey: WidgetSharedStorageKeys.pausedFocusTaskID)
        }

        saveTasks(tasks)
        saveHistory(history)
        saveDailyStats(stats)
        refreshWidgetTimelines()
    }

    static func startFocus(taskID: UUID?) {
        var tasks = loadTasks()
        guard !tasks.isEmpty else {
            return
        }

        var selectedIndex: Int?
        if let taskID {
            selectedIndex = tasks.firstIndex(where: { $0.id == taskID })
        }

        if selectedIndex == nil {
            selectedIndex = tasks.indices
                .filter { !tasks[$0].isExpired }
                .sorted { lhs, rhs in
                    let left = tasks[lhs]
                    let right = tasks[rhs]

                    if left.priority != right.priority {
                        return left.priority.rank > right.priority.rank
                    }

                    return left.deadline < right.deadline
                }
                .first
        }

        guard let selectedIndex else {
            return
        }

        for index in tasks.indices {
            tasks[index].isActive = false
        }

        tasks[selectedIndex].isActive = true
        tasks[selectedIndex].startedAt = Date()
        tasks[selectedIndex].isExpired = false

        defaults.removeObject(forKey: WidgetSharedStorageKeys.pausedFocusTaskID)
        saveTasks(tasks)
        refreshWidgetTimelines()
    }

    static func pauseFocus() {
        var tasks = loadTasks()
        guard let activeIndex = tasks.firstIndex(where: { $0.isActive }) else {
            return
        }

        defaults.set(tasks[activeIndex].id.uuidString, forKey: WidgetSharedStorageKeys.pausedFocusTaskID)
        tasks[activeIndex].isActive = false
        saveTasks(tasks)
        refreshWidgetTimelines()
    }

    static func resumeFocus() {
        guard let rawID = defaults.string(forKey: WidgetSharedStorageKeys.pausedFocusTaskID),
              let taskID = UUID(uuidString: rawID) else {
            return
        }

        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else {
            return
        }

        for taskIndex in tasks.indices {
            tasks[taskIndex].isActive = false
        }

        tasks[index].isActive = true
        tasks[index].startedAt = Date()
        tasks[index].isExpired = false

        defaults.removeObject(forKey: WidgetSharedStorageKeys.pausedFocusTaskID)
        saveTasks(tasks)
        refreshWidgetTimelines()
    }

    static func stopFocus() {
        var tasks = loadTasks()

        if let activeIndex = tasks.firstIndex(where: { $0.isActive }) {
            let focusDelta = tasks[activeIndex].focusTimeSpent
            tasks[activeIndex].isActive = false
            tasks[activeIndex].startedAt = nil
            saveTasks(tasks)

            var stats = loadDailyStats()
            stats.totalFocusTimeToday += focusDelta
            saveDailyStats(stats)
        }

        defaults.removeObject(forKey: WidgetSharedStorageKeys.pausedFocusTaskID)
        refreshWidgetTimelines()
    }

    static func quickAdd(kind: QuickAddPresetKind) {
        let now = Date()

        let template: (title: String, category: WidgetCategory, duration: TimeInterval, isPomodoro: Bool, priority: WidgetTaskPriority)
        switch kind {
        case .inbox:
            template = ("Inbox Task", .custom, 60 * 60, false, .medium)
        case .focusBlock:
            template = ("Focus Block", .coding, 90 * 60, true, .high)
        case .reminder:
            template = ("Reminder", .research, 30 * 60, false, .medium)
        }

        var tasks = loadTasks()
        let task = WidgetTask(
            id: UUID(),
            title: template.title,
            deadline: now.addingTimeInterval(template.duration),
            category: template.category,
            resources: [],
            isActive: false,
            isExpired: false,
            notes: "",
            priority: template.priority,
            estimatedDuration: template.duration,
            startedAt: nil,
            isPomodoroMode: template.isPomodoro,
            pomodoroWorkDuration: 25 * 60,
            pomodoroBreakDuration: 5 * 60,
            pomodoroLongBreakDuration: 15 * 60,
            pomodoroSessionsBeforeLongBreak: 4,
            pomodoroCurrentSession: 1,
            pomodoroIsOnBreak: false
        )

        tasks.append(task)
        saveTasks(tasks)
        refreshWidgetTimelines()
    }

    static func queuePendingCommand(action: WidgetPendingCommand.Action, taskID: String? = nil) {
        let command = WidgetPendingCommand(action: action, taskID: taskID)
        guard let data = try? JSONEncoder().encode(command) else {
            return
        }

        defaults.set(data, forKey: WidgetSharedStorageKeys.pendingWidgetCommand)
    }

    private static func saveTasks(_ tasks: [WidgetTask]) {
        do {
            let data = try PropertyListEncoder().encode(tasks)
            defaults.set(data, forKey: WidgetSharedStorageKeys.tasks)
            bumpSharedMutationToken()
        } catch {
            print("Widget task encode failed: \(error)")
        }
    }

    private static func loadHistory() -> [WidgetCompletedTask] {
        guard let data = defaults.data(forKey: WidgetSharedStorageKeys.taskHistory) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WidgetCompletedTask].self, from: data)
        } catch {
            print("Widget history decode failed: \(error)")
            return []
        }
    }

    private static func saveHistory(_ history: [WidgetCompletedTask]) {
        do {
            let data = try JSONEncoder().encode(history)
            defaults.set(data, forKey: WidgetSharedStorageKeys.taskHistory)
            bumpSharedMutationToken()
        } catch {
            print("Widget history encode failed: \(error)")
        }
    }

    private static func saveDailyStats(_ stats: WidgetDailyStats) {
        defaults.set(Date(), forKey: WidgetSharedStorageKeys.lastAnalyticsDate)
        defaults.set(stats.totalFocusTimeToday, forKey: WidgetSharedStorageKeys.totalFocusTimeToday)
        defaults.set(stats.tasksCompletedToday, forKey: WidgetSharedStorageKeys.tasksCompletedToday)
        defaults.set(stats.currentStreak, forKey: WidgetSharedStorageKeys.currentStreak)
        bumpSharedMutationToken()
    }

    private static func computeCurrentStreak(from history: [WidgetCompletedTask]) -> Int {
        guard !history.isEmpty else {
            return 0
        }

        var streak = 0
        var dateCursor = Date()

        while true {
            let hasTasksOnDay = history.contains { calendar.isDate($0.completedAt, inSameDayAs: dateCursor) }
            if !hasTasksOnDay {
                break
            }

            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dateCursor) else {
                break
            }
            dateCursor = previousDay
        }

        return streak
    }

    private static func refreshWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func bumpSharedMutationToken() {
        defaults.set(Date().timeIntervalSince1970, forKey: WidgetSharedStorageKeys.sharedMutationToken)
    }
}
