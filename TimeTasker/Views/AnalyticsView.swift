import SwiftUI

struct AnalyticsView: View {
    @ObservedObject var viewModel: TaskListViewModel

    private var weeklyTotalMinutes: Int {
        viewModel.weeklyStats.reduce(0) { partial, item in
            partial + item.minutes
        }
    }

    private var averageFocusSessionMinutes: Int {
        guard !viewModel.taskHistory.isEmpty else { return 0 }
        let totalMinutes = Int(viewModel.taskHistory.reduce(0) { $0 + $1.focusTime } / 60)
        return totalMinutes / max(viewModel.taskHistory.count, 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.accentColor)
                Text("Analytics")
                    .font(.headline)
                Spacer()
            }
            
            // Today's Stats
            HStack(spacing: 16) {
                StatCard(
                    title: "Today's Focus",
                    value: viewModel.todayFocusTimeFormatted,
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Tasks Done",
                    value: "\(viewModel.tasksCompletedToday)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Day Streak",
                    value: "\(viewModel.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }

            HStack(spacing: 10) {
                Label("\(weeklyTotalMinutes) min this week", systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Label("avg \(averageFocusSessionMinutes)m", systemImage: "waveform.path.ecg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 2)
            
            Divider()
            
            // Weekly Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                WeeklyChart(data: viewModel.weeklyStats)
            }
            
            Divider()
            
            // Category Breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus by Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if viewModel.categoryBreakdown.isEmpty {
                    Text("Complete tasks to see category breakdown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.categoryBreakdown.prefix(5), id: \.category) { item in
                        CategoryRow(category: item.category, count: item.count, total: viewModel.taskHistory.count)
                    }
                }
            }
            
            // Productivity Tips
            if let tip = getProductivityTip() {
                Divider()
                
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(tip)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .liquidGlassCard(cornerRadius: 10, tint: .yellow, tintOpacity: 0.14)
            }
        }
    }
    
    private func getProductivityTip() -> String? {
        if viewModel.currentStreak == 0 {
            return "Start your streak! Complete a task today to begin."
        } else if viewModel.currentStreak >= 7 {
            return "🔥 Amazing! You're on a \(viewModel.currentStreak)-day streak! Keep it up!"
        } else if viewModel.tasksCompletedToday == 0 {
            return "No tasks completed today. Pick one and get focused!"
        } else if viewModel.totalFocusTimeToday > 4 * 3600 {
            return "Great focus today! Remember to take breaks."
        }
        return nil
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .liquidGlassCard(cornerRadius: 10, tint: color, tintOpacity: 0.15)
    }
}

struct WeeklyChart: View {
    let data: [(day: String, minutes: Int)]
    
    var maxMinutes: Int {
        max(data.map { $0.minutes }.max() ?? 60, 60)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.day) { item in
                VStack(spacing: 4) {
                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.day == "Today" || isToday(item.day) ? Color.accentColor : Color.accentColor.opacity(0.5))
                        .frame(width: 28, height: max(4, CGFloat(item.minutes) / CGFloat(maxMinutes) * 80))
                    
                    // Label
                    Text(item.day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }
    
    private func isToday(_ dayName: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: Date()) == dayName
    }
}

struct CategoryRow: View {
    let category: Category
    let count: Int
    let total: Int
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category.iconName)
                .frame(width: 20)
                .foregroundColor(.accentColor)
            
            Text(category.rawValue)
                .font(.caption)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: max(4, geometry.size.width * percentage), height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

#Preview {
    AnalyticsView(viewModel: TaskListViewModel())
        .frame(width: 400)
        .padding()
}
