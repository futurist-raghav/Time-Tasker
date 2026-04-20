import SwiftUI
import WidgetKit
import AppIntents

private struct FocusSessionEntry: TimelineEntry {
    let date: Date
    let activeTask: WidgetTask?
    let pausedTask: WidgetTask?
    let nextTask: WidgetTask?
}

private struct FocusSessionProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusSessionEntry {
        FocusSessionEntry(date: Date(), activeTask: sampleTask, pausedTask: nil, nextTask: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusSessionEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusSessionEntry>) -> Void) {
        let entry = currentEntry()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func currentEntry() -> FocusSessionEntry {
        FocusSessionEntry(
            date: Date(),
            activeTask: WidgetTaskStore.loadActiveTask(),
            pausedTask: WidgetTaskStore.loadPausedTask(),
            nextTask: WidgetTaskStore.loadPendingTasks(limit: 1).first
        )
    }

    private var sampleTask: WidgetTask {
        WidgetTask(
            id: UUID(),
            title: "Deep work session",
            deadline: Date().addingTimeInterval(35 * 60),
            category: .coding,
            resources: [],
            isActive: true,
            isExpired: false,
            notes: "",
            priority: .high,
            estimatedDuration: 60 * 60,
            startedAt: Date().addingTimeInterval(-20 * 60),
            isPomodoroMode: true,
            pomodoroWorkDuration: 25 * 60,
            pomodoroBreakDuration: 5 * 60,
            pomodoroLongBreakDuration: 15 * 60,
            pomodoroSessionsBeforeLongBreak: 4,
            pomodoroCurrentSession: 2,
            pomodoroIsOnBreak: false
        )
    }
}

private struct FocusSessionWidgetView: View {
    let entry: FocusSessionEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if let activeTask = entry.activeTask {
                activeFocusView(activeTask)
            } else if let pausedTask = entry.pausedTask {
                pausedFocusView(pausedTask)
            } else {
                idleFocusView
            }

            Spacer(minLength: 0)

            footerActions
        }
        .padding(12)
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(.fill.tertiary)
        }
        .widgetURL(URL(string: "timetasker://focus"))
    }

    private var header: some View {
        HStack {
            Label("Current Session", systemImage: "timer")
                .font(.headline.weight(.semibold))

            Spacer(minLength: 0)

            if entry.activeTask != nil {
                stateChip("Live", tint: .green)
            } else if entry.pausedTask != nil {
                stateChip("Paused", tint: .orange)
            } else {
                stateChip("Idle", tint: .secondary)
            }
        }
    }

    private func activeFocusView(_ task: WidgetTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(family == .systemSmall ? 1 : 2)

            Text(task.deadline, style: .timer)
                .font(.system(size: family == .systemSmall ? 22 : 28, weight: .bold, design: .rounded))
                .monospacedDigit()

            if family != .systemSmall {
                progressBar(progress: progressValue(for: task))
            }

            HStack(spacing: 8) {
                Button(intent: PauseFocusIntent()) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(.bordered)

                if family != .systemSmall {
                    Button(intent: StopFocusIntent()) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .controlSize(.small)
        }
    }

    private func pausedFocusView(_ task: WidgetTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            Text("Session paused from widget")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button(intent: ResumeFocusIntent()) {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                if family != .systemSmall {
                    Button(intent: StopFocusIntent()) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .controlSize(.small)
        }
    }

    private var idleFocusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let nextTask = entry.nextTask {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Task")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(nextTask.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(family == .systemSmall ? 1 : 2)

                    Text(nextTask.deadline, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                }

                Button(intent: StartFocusIntent(taskID: nextTask.id.uuidString)) {
                    Label("Start Task", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Text("No task ready")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(intent: OpenQuickAddIntent()) {
                    Label("Quick Add Task", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private var footerActions: some View {
        HStack(spacing: 8) {
            Button(intent: OpenFocusIntent()) {
                Label("Open", systemImage: "arrow.up.right.square")
            }
            .buttonStyle(.bordered)

            if family != .systemSmall {
                Button(intent: OpenTodayIntent()) {
                    Label("Today", systemImage: "checklist")
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.small)
    }

    private func stateChip(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.18))
            }
    }

    private func progressValue(for task: WidgetTask) -> Double {
        guard task.estimatedDuration > 0 else {
            return 0
        }

        return min(max(task.focusTimeSpent / task.estimatedDuration, 0), 1)
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { proxy in
            let clamped = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.12))

                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.85))
                    .frame(width: proxy.size.width * clamped)
            }
        }
        .frame(height: 6)
    }
}

struct FocusSessionWidget: Widget {
    let kind: String = WidgetKindID.focusSession

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusSessionProvider()) { entry in
            FocusSessionWidgetView(entry: entry)
        }
        .configurationDisplayName("Current Session")
        .description("Start, pause, resume, and stop the current task session")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
