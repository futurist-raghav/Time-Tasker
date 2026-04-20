import Foundation
import AppIntents

enum WidgetTaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var rank: Int {
        switch self {
        case .urgent:
            return 4
        case .high:
            return 3
        case .medium:
            return 2
        case .low:
            return 1
        }
    }
}

enum WidgetCategory: String, Codable, CaseIterable {
    case coding = "Coding"
    case writing = "Writing"
    case design = "Design"
    case research = "Research"
    case custom = "Custom"
}

enum WidgetResourceType: String, Codable {
    case application
    case file
    case website
}

struct WidgetResource: Identifiable, Codable {
    let id: UUID
    var name: String
    var path: String
    var type: WidgetResourceType
}

struct WidgetTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var deadline: Date
    var category: WidgetCategory
    var resources: [WidgetResource]
    var isActive: Bool
    var isExpired: Bool
    var notes: String
    var priority: WidgetTaskPriority
    var estimatedDuration: TimeInterval
    var startedAt: Date?
    var isPomodoroMode: Bool
    var pomodoroWorkDuration: TimeInterval
    var pomodoroBreakDuration: TimeInterval
    var pomodoroLongBreakDuration: TimeInterval
    var pomodoroSessionsBeforeLongBreak: Int
    var pomodoroCurrentSession: Int
    var pomodoroIsOnBreak: Bool

    var timeRemaining: TimeInterval {
        deadline.timeIntervalSinceNow
    }

    var focusTimeSpent: TimeInterval {
        guard let startedAt else {
            return 0
        }

        return max(0, Date().timeIntervalSince(startedAt))
    }
}

struct WidgetCompletedTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let category: WidgetCategory
    let completedAt: Date
    let focusTime: TimeInterval
    let originalDeadline: Date
    let wasSuccessful: Bool
}

struct WidgetDailyStats {
    var totalFocusTimeToday: TimeInterval
    var tasksCompletedToday: Int
    var currentStreak: Int
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
}

enum QuickAddPresetKind: String, Codable, CaseIterable, AppEnum {
    case inbox
    case focusBlock
    case reminder

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Quick Add Preset"
    }

    static var caseDisplayRepresentations: [QuickAddPresetKind: DisplayRepresentation] {
        [
            .inbox: DisplayRepresentation(title: "Inbox Task"),
            .focusBlock: DisplayRepresentation(title: "Focus Block"),
            .reminder: DisplayRepresentation(title: "Reminder")
        ]
    }
}
