import AppIntents

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Task ID") var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskID) else {
            return .result()
        }

        WidgetTaskStore.completeTask(id: uuid)
        return .result()
    }
}

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Task ID") var taskID: String?

    init() {}

    init(taskID: String?) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        let uuid = taskID.flatMap(UUID.init(uuidString:))
        WidgetTaskStore.startFocus(taskID: uuid)
        return .result()
    }
}

struct PauseFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Focus"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetTaskStore.pauseFocus()
        return .result()
    }
}

struct ResumeFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Focus"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetTaskStore.resumeFocus()
        return .result()
    }
}

struct StopFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Focus"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetTaskStore.stopFocus()
        return .result()
    }
}

struct QuickAddPresetIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Task"
    static var description = IntentDescription("Adds a preset task to the queue")

    @Parameter(title: "Preset") var kind: QuickAddPresetKind

    init() {}

    init(kind: QuickAddPresetKind) {
        self.kind = kind
    }

    func perform() async throws -> some IntentResult {
        WidgetTaskStore.quickAdd(kind: kind)
        return .result()
    }
}

struct OpenTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Today"
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetTaskStore.queuePendingCommand(action: .openToday)
        return .result()
    }
}

struct OpenFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Focus"
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetTaskStore.queuePendingCommand(action: .openFocus)
        return .result()
    }
}

struct OpenQuickAddIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Quick Add"
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetTaskStore.queuePendingCommand(action: .openQuickAdd)
        return .result()
    }
}

struct OpenTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Task"
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    @Parameter(title: "Task ID") var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        WidgetTaskStore.queuePendingCommand(action: .openTask, taskID: taskID)
        return .result()
    }
}
