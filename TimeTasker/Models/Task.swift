import Foundation

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "flag"
        case .medium: return "flag.fill"
        case .high: return "exclamationmark.triangle"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

struct CompletedTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let category: Category
    let completedAt: Date
    let focusTime: TimeInterval  // Actual time spent focused
    let originalDeadline: Date
    let wasSuccessful: Bool  // Completed before deadline
    
    init(from task: Task, focusTime: TimeInterval) {
        self.id = task.id
        self.title = task.title
        self.category = task.category
        self.completedAt = Date()
        self.focusTime = focusTime
        self.originalDeadline = task.deadline
        self.wasSuccessful = !task.isExpired
    }
}

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var deadline: Date
    var category: Category
    var resources: [Resource]
    var isActive: Bool
    var isExpired: Bool
    
    // Enhanced features
    var notes: String
    var priority: TaskPriority
    var estimatedDuration: TimeInterval  // User estimated time
    var startedAt: Date?  // When task was first started
    
    // Pomodoro support
    var isPomodoroMode: Bool
    var pomodoroWorkDuration: TimeInterval
    var pomodoroBreakDuration: TimeInterval
    var pomodoroLongBreakDuration: TimeInterval
    var pomodoroSessionsBeforeLongBreak: Int
    var pomodoroCurrentSession: Int
    var pomodoroIsOnBreak: Bool

    init(
        id: UUID = UUID(),
        title: String,
        deadline: Date,
        category: Category,
        resources: [Resource] = [],
        isPomodoroMode: Bool = false,
        notes: String = "",
        priority: TaskPriority = .medium,
        estimatedDuration: TimeInterval = 3600,
        pomodoroWorkDuration: TimeInterval = 25 * 60,
        pomodoroBreakDuration: TimeInterval = 5 * 60,
        pomodoroLongBreakDuration: TimeInterval = 15 * 60,
        pomodoroSessionsBeforeLongBreak: Int = 4
    ) {
        self.id = id
        self.title = title
        self.deadline = deadline
        self.category = category
        self.resources = resources
        self.isActive = false
        self.isExpired = false
        
        // Enhanced features
        self.notes = notes
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.startedAt = nil
        
        // Pomodoro defaults
        self.isPomodoroMode = isPomodoroMode
        self.pomodoroWorkDuration = pomodoroWorkDuration
        self.pomodoroBreakDuration = pomodoroBreakDuration
        self.pomodoroLongBreakDuration = pomodoroLongBreakDuration
        self.pomodoroSessionsBeforeLongBreak = pomodoroSessionsBeforeLongBreak
        self.pomodoroCurrentSession = 1
        self.pomodoroIsOnBreak = false
    }

    var timeRemaining: TimeInterval {
        deadline.timeIntervalSinceNow
    }

    var formattedTimeRemaining: String {
        let interval = timeRemaining
        if interval < 0 {
            return "EXPIRED"
        }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    var pomodoroStatusText: String {
        if pomodoroIsOnBreak {
            return "Break Time"
        } else {
            return "Session \(pomodoroCurrentSession)"
        }
    }
    
    var focusTimeSpent: TimeInterval {
        guard let started = startedAt else { return 0 }
        return Date().timeIntervalSince(started)
    }
}
