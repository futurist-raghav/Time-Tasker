import SwiftUI
import WidgetKit
import AppIntents

private struct QuickAddStatsEntry: TimelineEntry {
    let date: Date
    let stats: WidgetDailyStats
    let nextTask: WidgetTask?
}

private struct QuickAddStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddStatsEntry {
        QuickAddStatsEntry(
            date: Date(),
            stats: WidgetDailyStats(totalFocusTimeToday: 2 * 3600, tasksCompletedToday: 4, currentStreak: 3),
            nextTask: WidgetTaskStore.loadPendingTasks(limit: 1).first
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAddStatsEntry) -> Void) {
        completion(
            QuickAddStatsEntry(
                date: Date(),
                stats: WidgetTaskStore.loadDailyStats(),
                nextTask: WidgetTaskStore.loadPendingTasks(limit: 1).first
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddStatsEntry>) -> Void) {
        let entry = QuickAddStatsEntry(
            date: Date(),
            stats: WidgetTaskStore.loadDailyStats(),
            nextTask: WidgetTaskStore.loadPendingTasks(limit: 1).first
        )
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

private struct QuickAddStatsWidgetView: View {
    let entry: QuickAddStatsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if family == .systemSmall {
                compactBody
            } else {
                expandedBody
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(.fill.tertiary)
        }
        .widgetURL(URL(string: "timetasker://quickadd"))
    }

    private var header: some View {
        HStack {
            Label("Quick Add", systemImage: "plus.circle")
                .font(.headline.weight(.semibold))

            Spacer(minLength: 0)

            Text("Today")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formatDuration(entry.stats.totalFocusTimeToday))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .lineLimit(1)

            HStack(spacing: 10) {
                compactMetric(label: "Done", value: "\(entry.stats.tasksCompletedToday)")
                compactMetric(label: "Streak", value: "\(entry.stats.currentStreak)")
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(intent: QuickAddPresetIntent(kind: .focusBlock)) {
                    Label("Focus", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(intent: OpenQuickAddIntent()) {
                    Label("Open", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.small)
        }
    }

    private var expandedBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                statTile(title: "Focus", value: formatDuration(entry.stats.totalFocusTimeToday), tint: .blue)
                statTile(title: "Done", value: "\(entry.stats.tasksCompletedToday)", tint: .green)
                statTile(title: "Streak", value: "\(entry.stats.currentStreak)", tint: .orange)
            }

            if let nextTask = entry.nextTask {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Task")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(nextTask.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Button(intent: StartFocusIntent(taskID: nextTask.id.uuidString)) {
                        Image(systemName: "play.fill")
                            .font(.caption.weight(.bold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                }
            }

            HStack(spacing: 6) {
                Button(intent: QuickAddPresetIntent(kind: .inbox)) {
                    Label("Inbox", systemImage: "tray.full")
                }
                .buttonStyle(.bordered)

                Button(intent: QuickAddPresetIntent(kind: .focusBlock)) {
                    Label("Focus", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(intent: QuickAddPresetIntent(kind: .reminder)) {
                    Label("Reminder", systemImage: "bell")
                }
                .buttonStyle(.bordered)

                Button(intent: OpenQuickAddIntent()) {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.small)
        }
    }

    private func compactMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold).monospacedDigit())
        }
    }

    private func statTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.14))
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }
}

struct QuickAddStatsWidget: Widget {
    let kind: String = WidgetKindID.quickAddStats

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddStatsProvider()) { entry in
            QuickAddStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Add & Stats")
        .description("Add tasks quickly and see your daily momentum")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
