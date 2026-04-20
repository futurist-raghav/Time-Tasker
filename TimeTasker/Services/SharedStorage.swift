import Foundation

enum SharedStorageConfiguration {
    static let appGroupIdentifier = "group.com.raghavagarwal.timetasker"
    static let fallbackSuiteIdentifier = "com.raghavagarwal.TimeTasker.shared"
}

enum SharedStorageKeys {
    static let tasks = "SavedTasksArray"
    static let taskHistory = "taskHistory"
    static let lastAnalyticsDate = "lastAnalyticsDate"
    static let totalFocusTimeToday = "totalFocusTimeToday"
    static let tasksCompletedToday = "tasksCompletedToday"
    static let currentStreak = "currentStreak"

    static let pendingWidgetCommand = "widgetPendingCommand"
    static let pausedFocusTaskID = "widgetPausedFocusTaskID"
}

enum WidgetKindIdentifier {
    static let todayTasks = "TodayTasksWidget"
    static let focusSession = "FocusSessionWidget"
    static let quickAddStats = "QuickAddStatsWidget"
}

final class SharedDefaultsProvider {
    static func sharedDefaults() -> UserDefaults {
        if let defaults = UserDefaults(suiteName: SharedStorageConfiguration.appGroupIdentifier) {
            return defaults
        }

        if let defaults = UserDefaults(suiteName: SharedStorageConfiguration.fallbackSuiteIdentifier) {
            return defaults
        }

        return .standard
    }
}

struct WidgetPendingCommand: Codable {
    enum Action: String, Codable {
        case openToday
        case openTask
        case openFocus
        case openQuickAdd
    }

    let action: Action
    let taskID: String?

    init(action: Action, taskID: String? = nil) {
        self.action = action
        self.taskID = taskID
    }
}

final class WidgetCommandBridge {
    static let shared = WidgetCommandBridge()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = SharedDefaultsProvider.sharedDefaults()) {
        self.defaults = defaults
    }

    func queue(_ command: WidgetPendingCommand) {
        guard let data = try? JSONEncoder().encode(command) else {
            return
        }

        defaults.set(data, forKey: SharedStorageKeys.pendingWidgetCommand)
    }

    func consumePendingCommand() -> WidgetPendingCommand? {
        guard let data = defaults.data(forKey: SharedStorageKeys.pendingWidgetCommand),
              let command = try? JSONDecoder().decode(WidgetPendingCommand.self, from: data) else {
            return nil
        }

        defaults.removeObject(forKey: SharedStorageKeys.pendingWidgetCommand)
        return command
    }
}
