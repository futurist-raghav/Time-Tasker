import Foundation

class DataPersistenceService {
    static let shared = DataPersistenceService()

    private let tasksKey = "SavedTasksArray"
    private let defaults = UserDefaults.standard

    private init() {}

    func saveTasks(_ tasks: [Task]) {
        do {
            let data = try PropertyListEncoder().encode(tasks)
            defaults.set(data, forKey: tasksKey)
        } catch {
            print("Error saving tasks: \(error)")
        }
    }

    func loadTasks() -> [Task] {
        guard let data = defaults.data(forKey: tasksKey) else {
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
}
