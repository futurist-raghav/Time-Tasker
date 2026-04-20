import SwiftUI
import WidgetKit
import AppIntents

private struct FocusSessionEntry: TimelineEntry {
    let date: Date
    let activeTask: WidgetTask?
    let pausedTask: WidgetTask?
}

private struct FocusSessionProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusSessionEntry {
        FocusSessionEntry(date: Date(), activeTask: sampleTask, pausedTask: nil)
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
            pausedTask: WidgetTaskStore.loadPausedTask()
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
            Label("Focus", systemImage: "timer")
                .font(.headline)

            if let activeTask = entry.activeTask {
                Text(activeTask.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(timeLabel(for: activeTask))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.primary)

                if family == .systemSmall {
                    HStack {
                        Button(intent: PauseFocusIntent()) {
                            Label("Pause", systemImage: "pause.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    HStack {
                        Button(intent: PauseFocusIntent()) {
                            Label("Pause", systemImage: "pause.fill")
                        }
                        .buttonStyle(.bordered)

                        Button(intent: StopFocusIntent()) {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else if let pausedTask = entry.pausedTask {
                Text("Paused")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(pausedTask.title)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack {
                    Button(intent: ResumeFocusIntent()) {
                        Label("Resume", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("No active session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(intent: StartFocusIntent(taskID: nil)) {
                    Label("Start Focus", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer(minLength: 0)

            Button(intent: OpenFocusIntent()) {
                Text("Open Focus")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    private func timeLabel(for task: WidgetTask) -> String {
        let remaining = max(0, Int(task.timeRemaining))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct FocusSessionWidget: Widget {
    let kind: String = WidgetKindID.focusSession

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusSessionProvider()) { entry in
            FocusSessionWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Session")
        .description("Start, pause, and resume focus sessions")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
