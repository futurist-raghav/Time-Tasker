import SwiftUI
import WidgetKit

@main
struct TimeTaskerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayTasksWidget()
        FocusSessionWidget()
        QuickAddStatsWidget()
    }
}
