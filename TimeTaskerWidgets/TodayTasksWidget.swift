import SwiftUI
import WidgetKit
import AppIntents

private struct TodayTasksEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
}

private struct TodayTasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayTasksEntry {
        TodayTasksEntry(date: Date(), tasks: sampleTasks)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayTasksEntry) -> Void) {
        let tasks = WidgetTaskStore.loadTodayTasks(limit: 5)
        completion(TodayTasksEntry(date: Date(), tasks: tasks.isEmpty ? sampleTasks : tasks))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayTasksEntry>) -> Void) {
        let entry = TodayTasksEntry(date: Date(), tasks: WidgetTaskStore.loadTodayTasks(limit: 5))
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date().addingTimeInterval(600)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private var sampleTasks: [WidgetTask] {
        [
            WidgetTask(
                id: UUID(),
                title: "Ship widget suite",
                deadline: Date().addingTimeInterval(90 * 60),
                category: .coding,
                resources: [],
                isActive: true,
                isExpired: false,
                notes: "",
                priority: .high,
                estimatedDuration: 90 * 60,
                startedAt: Date().addingTimeInterval(-15 * 60),
                isPomodoroMode: false,
                pomodoroWorkDuration: 25 * 60,
                pomodoroBreakDuration: 5 * 60,
                pomodoroLongBreakDuration: 15 * 60,
                pomodoroSessionsBeforeLongBreak: 4,
                pomodoroCurrentSession: 1,
                pomodoroIsOnBreak: false
            ),
            WidgetTask(
                id: UUID(),
                title: "Plan tomorrow",
                deadline: Date().addingTimeInterval(3 * 3600),
                category: .research,
                resources: [],
                isActive: false,
                isExpired: false,
                notes: "",
                priority: .medium,
                estimatedDuration: 30 * 60,
                startedAt: nil,
                isPomodoroMode: false,
                pomodoroWorkDuration: 25 * 60,
                pomodoroBreakDuration: 5 * 60,
                pomodoroLongBreakDuration: 15 * 60,
                pomodoroSessionsBeforeLongBreak: 4,
                pomodoroCurrentSession: 1,
                pomodoroIsOnBreak: false
            )
        ]
    }
}

private struct TodayTasksWidgetView: View {
    let entry: TodayTasksEntry
    @Environment(\.widgetFamily) private var family

    private var maxTasks: Int {
        switch family {
        case .systemLarge:
            return 5
        default:
            return 3
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Today", systemImage: "checklist")
                    .font(.headline)
                Spacer()
                Text("\(entry.tasks.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if entry.tasks.isEmpty {
                Text("No tasks queued")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(entry.tasks.prefix(maxTasks))) { task in
                        HStack(spacing: 8) {
                            Button(intent: CompleteTaskIntent(taskID: task.id.uuidString)) {
                                Image(systemName: task.isExpired ? "xmark.circle" : "checkmark.circle")
                                    .foregroundStyle(task.isExpired ? .orange : .green)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(task.title)
                                    .font(.subheadline.weight(task.isActive ? .semibold : .regular))
                                    .lineLimit(1)

                                Text(timeLabel(for: task))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)

                            Button(intent: OpenTaskIntent(taskID: task.id.uuidString)) {
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Button(intent: OpenTodayIntent()) {
                Text("Open Today")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
    }

    private func timeLabel(for task: WidgetTask) -> String {
        if task.isExpired || task.timeRemaining < 0 {
            return "Overdue"
        }

        let interval = Int(task.timeRemaining)
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        }

        return "\(minutes)m left"
    }
}

struct TodayTasksWidget: Widget {
    let kind: String = WidgetKindID.todayTasks

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTasksProvider()) { entry in
            TodayTasksWidgetView(entry: entry)
        }
        .configurationDisplayName("Today Tasks")
        .description("View and complete your top tasks without opening the app")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
