import Foundation

struct DailyAnalyticsState {
    var lastAnalyticsDate: Date?
    var totalFocusTimeToday: TimeInterval
    var tasksCompletedToday: Int
    var currentStreak: Int
}

class DataPersistenceService {
    static let shared = DataPersistenceService()

    private let defaults: UserDefaults
    private let legacyDefaults: UserDefaults

    private var migrationKeys: [String] {
        [
            SharedStorageKeys.tasks,
            SharedStorageKeys.taskHistory,
            SharedStorageKeys.lastAnalyticsDate,
            SharedStorageKeys.totalFocusTimeToday,
            SharedStorageKeys.tasksCompletedToday,
            SharedStorageKeys.currentStreak,
            SharedStorageKeys.pendingWidgetCommand,
            SharedStorageKeys.pausedFocusTaskID
        ]
    }

    private init(
        defaults: UserDefaults = SharedDefaultsProvider.sharedDefaults(),
        legacyDefaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        self.legacyDefaults = legacyDefaults
        migrateLegacyDataIfNeeded()
    }

    func saveTasks(_ tasks: [Task]) {
        do {
            let data = try PropertyListEncoder().encode(tasks)
            defaults.set(data, forKey: SharedStorageKeys.tasks)
        } catch {
            print("Error saving tasks: \(error)")
        }
    }

    func loadTasks() -> [Task] {
        guard let data = defaults.data(forKey: SharedStorageKeys.tasks) else {
            return []
        }

        do {
            let tasks = try PropertyListDecoder().decode([Task].self, from: data)
            return tasks
        } catch {
            print("Error loading tasks: \(error)")
            return []
        }
    }

    func saveTaskHistory(_ history: [CompletedTask]) {
        do {
            let data = try JSONEncoder().encode(history)
            defaults.set(data, forKey: SharedStorageKeys.taskHistory)
        } catch {
            print("Error saving task history: \(error)")
        }
    }

    func loadTaskHistory() -> [CompletedTask] {
        guard let data = defaults.data(forKey: SharedStorageKeys.taskHistory) else {
            return []
        }

        do {
            return try JSONDecoder().decode([CompletedTask].self, from: data)
        } catch {
            print("Error loading task history: \(error)")
            return []
        }
    }

    func loadDailyAnalyticsState() -> DailyAnalyticsState {
        DailyAnalyticsState(
            lastAnalyticsDate: defaults.object(forKey: SharedStorageKeys.lastAnalyticsDate) as? Date,
            totalFocusTimeToday: defaults.double(forKey: SharedStorageKeys.totalFocusTimeToday),
            tasksCompletedToday: defaults.integer(forKey: SharedStorageKeys.tasksCompletedToday),
            currentStreak: defaults.integer(forKey: SharedStorageKeys.currentStreak)
        )
    }

    func saveDailyAnalyticsState(_ state: DailyAnalyticsState) {
        defaults.set(state.lastAnalyticsDate, forKey: SharedStorageKeys.lastAnalyticsDate)
        defaults.set(state.totalFocusTimeToday, forKey: SharedStorageKeys.totalFocusTimeToday)
        defaults.set(state.tasksCompletedToday, forKey: SharedStorageKeys.tasksCompletedToday)
        defaults.set(state.currentStreak, forKey: SharedStorageKeys.currentStreak)
    }

    func clearAllPersistentData() {
        for key in migrationKeys {
            defaults.removeObject(forKey: key)
            if defaults !== legacyDefaults {
                legacyDefaults.removeObject(forKey: key)
            }
        }
    }

    static func resetPersistentDataForUITesting() {
        let defaults = SharedDefaultsProvider.sharedDefaults()
        let legacyDefaults = UserDefaults.standard
        let keys = [
            SharedStorageKeys.tasks,
            SharedStorageKeys.taskHistory,
            SharedStorageKeys.lastAnalyticsDate,
            SharedStorageKeys.totalFocusTimeToday,
            SharedStorageKeys.tasksCompletedToday,
            SharedStorageKeys.currentStreak,
            SharedStorageKeys.pendingWidgetCommand,
            SharedStorageKeys.pausedFocusTaskID
        ]

        for key in keys {
            defaults.removeObject(forKey: key)
            if defaults !== legacyDefaults {
                legacyDefaults.removeObject(forKey: key)
            }
        }
    }

    private func migrateLegacyDataIfNeeded() {
        guard defaults !== legacyDefaults else {
            return
        }

        for key in migrationKeys where defaults.object(forKey: key) == nil {
            if let legacyValue = legacyDefaults.object(forKey: key) {
                defaults.set(legacyValue, forKey: key)
            }
        }
    }
}
