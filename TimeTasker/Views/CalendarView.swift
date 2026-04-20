import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                CalendarToolbarButton(systemImage: "chevron.left", action: previousMonth)
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()

                Button("Today") {
                    withAnimation(.spring(duration: 0.35)) {
                        selectedDate = Date()
                        currentMonth = Date()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                CalendarToolbarButton(systemImage: "chevron.right", action: nextMonth)
            }
            .padding(.horizontal)
            
            // Day Headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        tasks: tasksFor(date: date)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Selected Date Tasks
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tasks for \(selectedDateString)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if !tasksFor(date: selectedDate).isEmpty {
                        Text("\(tasksFor(date: selectedDate).count) task(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                let dayTasks = tasksFor(date: selectedDate)
                
                if dayTasks.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.secondary)
                        Text("No tasks due on this day")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    .padding(.vertical, 8)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(dayTasks) { task in
                                CalendarTaskRow(task: task, onStart: {
                                    viewModel.startTask(task)
                                })
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Helper Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Helper Methods
    
    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func daysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        var dates: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    private func tasksFor(date: Date) -> [Task] {
        viewModel.tasks.filter { task in
            calendar.isDate(task.deadline, inSameDayAs: date)
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let tasks: [Task]
    
    private let calendar = Calendar.current
    private var hasTasks: Bool { !tasks.isEmpty }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(.body, design: .rounded))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(textColor)
            
            // Task indicator dots
            HStack(spacing: 2) {
                ForEach(0..<min(tasks.count, 3), id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: tasks[index]))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(width: 40, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.accentColor : (hasTasks ? Color.accentColor.opacity(0.35) : Color.clear), lineWidth: hasTasks ? 1.2 : 2)
        )
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isSelected {
            return .primary
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.24)
        } else if isToday {
            return Color.accentColor.opacity(0.14)
        } else if hasTasks {
            return Color.white.opacity(0.06)
        } else {
            return Color.clear
        }
    }
    
    private func dotColor(for task: Task) -> Color {
        if task.isActive {
            return .green
        } else if task.isExpired {
            return .red
        } else {
            return .accentColor
        }
    }
}

struct CalendarTaskRow: View {
    let task: Task
    let onStart: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Category icon
            Image(systemName: task.category.iconName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Task info
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(task.formattedTimeRemaining)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Start button (if not active)
            if !task.isActive && !task.isExpired {
                Button(action: onStart) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.18))
                .foregroundColor(.green)
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .liquidGlassCard(cornerRadius: 8, tint: statusColor, tintOpacity: 0.12, strokeOpacity: 0.5, shadowOpacity: 0.08)
    }
    
    private var statusColor: Color {
        if task.isActive {
            return .green
        } else if task.isExpired {
            return .red
        } else {
            return .blue
        }
    }
}

struct CalendarToolbarButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CalendarView(viewModel: TaskListViewModel())
        .frame(width: 350, height: 500)
}
