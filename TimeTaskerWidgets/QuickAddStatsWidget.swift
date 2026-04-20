import SwiftUI
import WidgetKit
import AppIntents

private struct QuickAddStatsEntry: TimelineEntry {
    let date: Date
    let stats: WidgetDailyStats
}

private struct QuickAddStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddStatsEntry {
        QuickAddStatsEntry(
            date: Date(),
            stats: WidgetDailyStats(totalFocusTimeToday: 2 * 3600, tasksCompletedToday: 4, currentStreak: 3)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAddStatsEntry) -> Void) {
        completion(QuickAddStatsEntry(date: Date(), stats: WidgetTaskStore.loadDailyStats()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddStatsEntry>) -> Void) {
        let entry = QuickAddStatsEntry(date: Date(), stats: WidgetTaskStore.loadDailyStats())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

private struct QuickAddStatsWidgetView: View {
    let entry: QuickAddStatsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quick Add", systemImage: "plus.circle")
                .font(.headline)

            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatDuration(entry.stats.totalFocusTimeToday))
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button(intent: QuickAddPresetIntent(kind: .focusBlock)) {
                    Label("Add Focus", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)
            } else {
                HStack {
                    statTile(title: "Focus", value: formatDuration(entry.stats.totalFocusTimeToday))
                    statTile(title: "Done", value: "\(entry.stats.tasksCompletedToday)")
                    statTile(title: "Streak", value: "\(entry.stats.currentStreak)")
                }

                Spacer(minLength: 0)

                HStack {
                    Button(intent: QuickAddPresetIntent(kind: .inbox)) {
                        Label("Inbox", systemImage: "tray.full")
                    }
                    .buttonStyle(.bordered)

                    Button(intent: QuickAddPresetIntent(kind: .focusBlock)) {
                        Label("Focus", systemImage: "bolt.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(intent: OpenQuickAddIntent()) {
                        Label("More", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(12)
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
