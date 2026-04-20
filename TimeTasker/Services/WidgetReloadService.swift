import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetReloadService {
    static func reloadAllTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func reloadTaskAndFocusWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKindIdentifier.todayTasks)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKindIdentifier.focusSession)
        #endif
    }

    static func reloadStatsWidget() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKindIdentifier.quickAddStats)
        #endif
    }
}
