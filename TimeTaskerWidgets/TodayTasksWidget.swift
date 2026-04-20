import SwiftUI
import WidgetKit
import AppIntents

private struct TodayTasksEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let pendingCount: Int
    let overdueCount: Int
    let activeCount: Int
}

private struct TodayTasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayTasksEntry {
        makeEntry(useSampleIfEmpty: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayTasksEntry) -> Void) {
        completion(makeEntry(useSampleIfEmpty: context.isPreview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayTasksEntry>) -> Void) {
        let entry = makeEntry(useSampleIfEmpty: false)
        let refreshMinutes = context.family == .systemLarge ? 1 : 10
        let refreshDate = Calendar.current.date(byAdding: .minute, value: refreshMinutes, to: Date()) ?? Date().addingTimeInterval(TimeInterval(refreshMinutes * 60))
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func makeEntry(useSampleIfEmpty: Bool) -> TodayTasksEntry {
        let loadedTasks = WidgetTaskStore.loadTasks()
        let sourceTasks: [WidgetTask]

        if loadedTasks.isEmpty && useSampleIfEmpty {
            sourceTasks = sampleTasks
        } else {
            sourceTasks = loadedTasks
        }

        let pendingCount = sourceTasks.filter { !$0.isActive && !$0.isExpired }.count
        let overdueCount = sourceTasks.filter { $0.isExpired }.count
        let activeCount = sourceTasks.filter { $0.isActive }.count

        let visibleTasks = sourceTasks
            .filter { $0.isActive || !$0.isExpired }
            .sorted { lhs, rhs in
                if lhs.isActive != rhs.isActive {
                    return lhs.isActive
                }

                if lhs.priority != rhs.priority {
                    return lhs.priority.rank > rhs.priority.rank
                }

                return lhs.deadline < rhs.deadline
            }

        return TodayTasksEntry(
            date: Date(),
            tasks: visibleTasks,
            pendingCount: pendingCount,
            overdueCount: overdueCount,
            activeCount: activeCount
        )
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

    private var visibleTasks: [WidgetTask] {
        Array(entry.tasks.prefix(maxTasks))
    }

    private var nextTaskToStart: WidgetTask? {
        visibleTasks.first(where: { !$0.isActive })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if visibleTasks.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(visibleTasks) { task in
                        taskRow(task)
                    }
                }
            }

            Spacer(minLength: 0)

            footerActions
        }
        .padding(12)
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(.fill.tertiary)
        }
        .widgetURL(URL(string: "timetasker://today"))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Label("Today", systemImage: "checklist")
                    .font(.headline.weight(.semibold))

                Spacer(minLength: 0)

                if family == .systemLarge {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.date, style: .time)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .monospacedDigit()

                        Text(entry.date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if entry.activeCount > 0 {
                    statusChip(title: "Live", icon: "timer", tint: .green)
                }
            }

            HStack(spacing: 6) {
                statusChip(title: "\(entry.pendingCount) Pending", icon: "tray", tint: .blue)

                if entry.overdueCount > 0 {
                    statusChip(title: "\(entry.overdueCount) Overdue", icon: "exclamationmark.triangle", tint: .orange)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nothing queued")
                .font(.subheadline.weight(.semibold))
            Text("Add your next focus block from Quick Add.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    private func taskRow(_ task: WidgetTask) -> some View {
        HStack(spacing: 8) {
            Button(intent: CompleteTaskIntent(taskID: task.id.uuidString)) {
                Image(systemName: task.isExpired ? "xmark.circle.fill" : "checkmark.circle")
                    .foregroundStyle(task.isExpired ? .orange : .green)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(task.isActive ? .semibold : .regular))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(task.priority.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Circle()
                        .frame(width: 3, height: 3)
                        .foregroundStyle(.secondary)

                    if task.isActive {
                        Text(task.deadline, style: .timer)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.primary)
                    } else {
                        Text(task.deadline, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            if task.isActive {
                Button(intent: PauseFocusIntent()) {
                    Image(systemName: "pause.fill")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            } else {
                Button(intent: StartFocusIntent(taskID: task.id.uuidString)) {
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Button(intent: OpenTaskIntent(taskID: task.id.uuidString)) {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.08))
        }
    }

    private var footerActions: some View {
        HStack(spacing: 8) {
            if entry.activeCount == 0, let nextTaskToStart {
                Button(intent: StartFocusIntent(taskID: nextTaskToStart.id.uuidString)) {
                    Label("Start Top", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            if entry.activeCount == 0 {
                Button(intent: OpenTodayIntent()) {
                    Label("Open", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            } else {
                Button(intent: OpenTodayIntent()) {
                    Label("Open", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.borderedProminent)
            }

            if family == .systemLarge {
                Button(intent: OpenQuickAddIntent()) {
                    Label("Quick Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.small)
    }

    private func statusChip(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background {
            Capsule(style: .continuous)
                .fill(tint.opacity(0.18))
        }
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
