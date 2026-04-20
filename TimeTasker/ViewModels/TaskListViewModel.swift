import Foundation
import Combine
import AppKit
import SwiftUI

class TaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var taskHistory: [CompletedTask] = []
    @Published var activeTask: Task?
    @Published var pomodoroStatus: String = ""
    
    // Analytics
    @Published var totalFocusTimeToday: TimeInterval = 0
    @Published var tasksCompletedToday: Int = 0
    @Published var currentStreak: Int = 0

    private var timer: Timer?
    private let dataService = DataPersistenceService.shared
    private let sharedDefaults = SharedDefaultsProvider.sharedDefaults()
    private var lastObservedMutationToken: TimeInterval = 0
    private var syncHeartbeatCounter = 0

    init() {
        loadTasks()
        loadHistory()
        loadAnalytics()
        lastObservedMutationToken = sharedDefaults.double(forKey: SharedStorageKeys.sharedMutationToken)
        startTimer()
    }

    // MARK: - Task Management

    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()

        if tasks.count == 1 {
            startTask(task)
        }
    }

    func deleteTask(at indexSet: IndexSet) {
        tasks.remove(atOffsets: indexSet)
        saveTasks()
    }

    func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        saveTasks()
    }

    func startTask(_ task: Task) {
        if let activeIndex = tasks.firstIndex(where: { $0.isActive }) {
            tasks[activeIndex].isActive = false
        }

        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isActive = true
            tasks[index].startedAt = Date()
            activeTask = tasks[index]
            
            if tasks[index].isPomodoroMode {
                pomodoroStatus = tasks[index].pomodoroStatusText
            }
            
            NotificationCenter.default.post(name: .taskActivated, object: tasks[index])
            saveTasks()
            print("▶️ Started task: \(task.title)")
        }
    }

    func stopTask() {
        if let activeIndex = tasks.firstIndex(where: { $0.isActive }) {
            let task = tasks[activeIndex]
            let focusTime = task.focusTimeSpent
            
            tasks[activeIndex].isActive = false
            activeTask = nil
            pomodoroStatus = ""
            NotificationCenter.default.post(name: .taskStopped, object: nil)
            saveTasks()
            
            // Update analytics
            totalFocusTimeToday += focusTime
            saveAnalytics()
            
            print("⏹ Stopped task after \(Int(focusTime / 60)) minutes")
        }
    }
    
    func completeTask(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let focusTime = tasks[index].focusTimeSpent
        let completedTask = CompletedTask(from: tasks[index], focusTime: focusTime)
        taskHistory.insert(completedTask, at: 0)  // Add to beginning
        
        // Update analytics
        totalFocusTimeToday += focusTime
        tasksCompletedToday += 1
        updateStreak()
        
        // Remove from active tasks
        if tasks[index].isActive {
            activeTask = nil
            pomodoroStatus = ""
            NotificationCenter.default.post(name: .taskStopped, object: nil)
        }
        tasks.remove(at: index)
        
        saveTasks()
        saveHistory()
        saveAnalytics()
        
        print("✅ Completed task: \(task.title)")
    }
    
    // MARK: - Analytics
    
    var todayFocusTimeFormatted: String {
        let hours = Int(totalFocusTimeToday) / 3600
        let minutes = (Int(totalFocusTimeToday) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var weeklyStats: [(day: String, minutes: Int)] {
        let calendar = Calendar.current
        var stats: [(String, Int)] = []
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayName = dayFormatter.string(from: date)
            
            let dayTasks = taskHistory.filter { calendar.isDate($0.completedAt, inSameDayAs: date) }
            let totalMinutes = Int(dayTasks.reduce(0) { $0 + $1.focusTime } / 60)
            
            stats.append((dayName, totalMinutes))
        }
        
        return stats
    }
    
    var categoryBreakdown: [(category: Category, count: Int)] {
        var counts: [Category: Int] = [:]
        for task in taskHistory {
            counts[task.category, default: 0] += 1
        }
        return counts.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }
    }
    
    private func updateStreak() {
        // Check if user has completed tasks on consecutive days
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        while true {
            let hasTasksOnDay = taskHistory.contains { calendar.isDate($0.completedAt, inSameDayAs: checkDate) }
            if hasTasksOnDay {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        currentStreak = streak
    }

    // MARK: - Timer Management

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTaskStates()
        }
    }

    private func updateTaskStates() {
        syncHeartbeatCounter += 1
        if syncHeartbeatCounter >= 5 {
            syncHeartbeatCounter = 0
            syncFromSharedStoreIfNeeded()
        }

        var needsSave = false
        
        for index in tasks.indices {
            if tasks[index].timeRemaining < 0 && !tasks[index].isExpired {
                if tasks[index].isPomodoroMode && tasks[index].isActive {
                    handlePomodoroTransition(at: index)
                    needsSave = true
                } else {
                    tasks[index].isExpired = true
                    if tasks[index].isActive {
                        showExpirationAlert(for: tasks[index])
                    }
                }
            }
        }
        
        if let activeIndex = tasks.firstIndex(where: { $0.isActive }) {
            activeTask = tasks[activeIndex]
            if tasks[activeIndex].isPomodoroMode {
                pomodoroStatus = tasks[activeIndex].pomodoroStatusText
            }
        }
        
        if needsSave {
            saveTasks()
        }
        
        objectWillChange.send()
    }

    func syncFromSharedStoreIfNeeded(force: Bool = false) {
        let mutationToken = sharedDefaults.double(forKey: SharedStorageKeys.sharedMutationToken)
        guard force || mutationToken > lastObservedMutationToken + 0.0001 else {
            return
        }

        lastObservedMutationToken = mutationToken

        tasks = dataService.loadTasks()
        taskHistory = dataService.loadTaskHistory()
        activeTask = tasks.first(where: { $0.isActive })

        if let activeTask, activeTask.isPomodoroMode {
            pomodoroStatus = activeTask.pomodoroStatusText
        } else {
            pomodoroStatus = ""
        }

        loadAnalytics()
    }
    
    private func handlePomodoroTransition(at index: Int) {
        let task = tasks[index]
        
        if task.pomodoroIsOnBreak {
            tasks[index].pomodoroIsOnBreak = false
            tasks[index].pomodoroCurrentSession += 1
            tasks[index].deadline = Date().addingTimeInterval(task.pomodoroWorkDuration)
            tasks[index].isExpired = false
            
            showPomodoroNotification(title: "Break Over!", message: "Time to focus! Session \(tasks[index].pomodoroCurrentSession) starting.")
            NSSound.beep()
            
        } else {
            tasks[index].pomodoroIsOnBreak = true
            
            let isLongBreak = task.pomodoroCurrentSession % task.pomodoroSessionsBeforeLongBreak == 0
            let breakDuration = isLongBreak ? task.pomodoroLongBreakDuration : task.pomodoroBreakDuration
            
            tasks[index].deadline = Date().addingTimeInterval(breakDuration)
            tasks[index].isExpired = false
            
            let breakType = isLongBreak ? "Long Break" : "Short Break"
            showPomodoroNotification(title: "Session Complete! 🎉", message: "\(breakType) time! Take a \(Int(breakDuration / 60)) minute break.")
            NSSound(named: "Glass")?.play()
        }
        
        pomodoroStatus = tasks[index].pomodoroStatusText
    }
    
    private func showPomodoroNotification(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showExpirationAlert(for task: Task) {
        let alert = NSAlert()
        alert.messageText = "Task Deadline Reached"
        alert.informativeText = "\"\(task.title)\" has reached its deadline."
        alert.addButton(withTitle: "Mark Complete")
        alert.addButton(withTitle: "Continue Working")
        alert.addButton(withTitle: "Stop & Next Task")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completeTask(task)
            if let nextTask = tasks.first(where: { !$0.isActive && !$0.isExpired }) {
                startTask(nextTask)
            }
        } else if response == .alertThirdButtonReturn {
            stopTask()
            if let nextTask = tasks.first(where: { !$0.isActive && !$0.isExpired }) {
                startTask(nextTask)
            }
        }
    }

    // MARK: - Persistence

    private func loadTasks() {
        tasks = dataService.loadTasks()
    }

    private func saveTasks() {
        dataService.saveTasks(tasks)
        lastObservedMutationToken = sharedDefaults.double(forKey: SharedStorageKeys.sharedMutationToken)
        WidgetReloadService.reloadTaskAndFocusWidgets()
    }
    
    private func loadHistory() {
        taskHistory = dataService.loadTaskHistory()
    }
    
    private func saveHistory() {
        dataService.saveTaskHistory(taskHistory)
        lastObservedMutationToken = sharedDefaults.double(forKey: SharedStorageKeys.sharedMutationToken)
        WidgetReloadService.reloadStatsWidget()
    }
    
    private func loadAnalytics() {
        let calendar = Calendar.current
        let today = Date()
        let analytics = dataService.loadDailyAnalyticsState()
        
        // Reset daily stats if it's a new day.
        if let lastDate = analytics.lastAnalyticsDate,
           !calendar.isDate(lastDate, inSameDayAs: today) {
            totalFocusTimeToday = 0
            tasksCompletedToday = 0
        } else {
            totalFocusTimeToday = analytics.totalFocusTimeToday
            tasksCompletedToday = analytics.tasksCompletedToday
        }
        
        currentStreak = analytics.currentStreak
        updateStreak()
    }
    
    private func saveAnalytics() {
        let analytics = DailyAnalyticsState(
            lastAnalyticsDate: Date(),
            totalFocusTimeToday: totalFocusTimeToday,
            tasksCompletedToday: tasksCompletedToday,
            currentStreak: currentStreak
        )

        dataService.saveDailyAnalyticsState(analytics)
        lastObservedMutationToken = sharedDefaults.double(forKey: SharedStorageKeys.sharedMutationToken)
        WidgetReloadService.reloadStatsWidget()
    }

    deinit {
        timer?.invalidate()
    }
}

extension Notification.Name {
    static let taskActivated = Notification.Name("taskActivated")
    static let taskStopped = Notification.Name("taskStopped")
}
