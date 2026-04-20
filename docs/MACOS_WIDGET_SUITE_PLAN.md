# TimeTasker macOS Widget Suite Plan

## Objective

Add a focused macOS widget suite that gives users high-value actions without opening the full app:

- See today's tasks at a glance.
- Track focus/time progress in real time-like snapshots.
- Add a new task in one click.

V1 should ship as a **3-widget suite** to keep delivery fast and stable.

## V1 Widget Suite (3 Widgets)

### 1) Today Tasks Widget

**Primary job:** Show the most important tasks for today and let users complete tasks quickly.

**Best families:** `.systemMedium`, `.systemLarge`

**Content:**

- Top 3 to 5 tasks sorted by active first, then nearest deadline.
- Status hints: active, overdue, upcoming.
- Compact footer with "Open Today".

**Actions:**

- Complete task from widget (button/toggle backed by App Intent).
- Tap task row to open task detail in app.
- Tap widget background to open Today screen.

**Why this matters for TimeTasker:**

- Directly maps to `TaskListViewModel.tasks` and existing `completeTask(_:)` flow.
- Reduces friction for quick task maintenance during deep work.

### 2) Focus Session Widget

**Primary job:** Control and monitor current focus session.

**Best families:** `.systemSmall`, `.systemMedium`

**Content:**

- Current focus state: no session, running, paused.
- Current task title (if active).
- Session timer value:
  - Remaining time for deadline/Pomodoro block.
  - Optional elapsed focus time.

**Actions:**

- Start focus (optionally using current top task).
- Pause/Resume session.
- Stop session.

**Why this matters for TimeTasker:**

- Leverages existing `startTask(_:)` and `stopTask()` behavior.
- Surfaces Pomodoro/session context from existing task model fields (`isPomodoroMode`, session/break state).

### 3) Quick Add + Daily Progress Widget

**Primary job:** Let users add a task instantly while still seeing lightweight daily metrics.

**Best families:** `.systemSmall`, `.systemMedium`

**Content:**

- One clear "Add Task" action.
- Daily metrics summary:
  - Focused today.
  - Tasks completed today.
  - Current streak.

**Actions:**

- One-tap preset add (for example: Inbox Task, Focus Block).
- Open app directly to quick capture screen for full text entry.

**Why this matters for TimeTasker:**

- Uses existing analytics values (`totalFocusTimeToday`, `tasksCompletedToday`, `currentStreak`).
- Satisfies "add new task" requirement from desktop with minimal context switching.

## Interaction Model (App Intents)

Use App Intents for all in-widget actions. Intents must finish persistence writes before returning so timelines reload with correct state.

Initial intents for V1:

- `CompleteTaskIntent(taskID: UUID)`
- `StartFocusIntent(taskID: UUID?)`
- `PauseFocusIntent()`
- `ResumeFocusIntent()`
- `StopFocusIntent()`
- `QuickAddPresetIntent(kind: QuickAddKind)`

Optional V1.1 intents:

- `SkipBreakIntent()` for Pomodoro break control.

## Data + Persistence Architecture

Widgets run in a separate process, so they must read/write shared persisted data instead of app memory.

### Shared storage approach

1. Introduce an App Group (for example: `group.com.futuristraghav.TimeTasker`).
2. Move task/history/analytics storage to shared `UserDefaults(suiteName:)`.
3. Keep keys centralized in one shared constants file.
4. Use a shared repository abstraction accessible by both app and widget extension.

### Existing app data to expose to widgets

- Tasks: currently stored by `DataPersistenceService` under `SavedTasksArray`.
- History: currently `taskHistory` key.
- Analytics: `totalFocusTimeToday`, `tasksCompletedToday`, `currentStreak`, `lastAnalyticsDate`.

### Widget read model

Define a lightweight snapshot model the timeline provider can consume quickly:

- `todayTasks: [TaskWidgetItem]`
- `activeSession: FocusSessionWidgetState?`
- `stats: DailyStatsWidgetState`
- `lastUpdated: Date`

## Timeline + Refresh Strategy

Use timeline entries for forecasted updates, plus explicit reloads on writes.

- Baseline timeline refresh every 5 to 15 minutes.
- Immediate reload triggers after:
  - add task
  - complete task
  - start/pause/resume/stop focus
  - day rollover analytics reset
- Use targeted reloads by widget kind where possible:
  - `WidgetCenter.shared.reloadTimelines(ofKind: "TodayTasksWidget")`
  - `WidgetCenter.shared.reloadTimelines(ofKind: "FocusSessionWidget")`
  - `WidgetCenter.shared.reloadTimelines(ofKind: "QuickAddStatsWidget")`

## Deep Link Routing

Add URL routes so widget taps open exactly the intended destination:

- `timetasker://today`
- `timetasker://task/{id}`
- `timetasker://focus`
- `timetasker://quick-add`

## UX Rules for This Suite

- One primary action per widget.
- Max one to two secondary actions.
- Keep text minimal and state obvious.
- Prefer system widget backgrounds and native typography.
- Do not mirror full dashboard complexity inside widget views.

## Delivery Plan

### Phase 1 - Foundation

- Add Widget Extension target.
- Add App Group capability to app + extension.
- Refactor persistence to shared store and create widget snapshot repository.

### Phase 2 - Today Tasks Widget

- Build read-only timeline view.
- Add complete action via `CompleteTaskIntent`.
- Add deep links for task row and Today screen.

### Phase 3 - Focus Session Widget

- Implement focus state timeline.
- Add Start/Pause/Resume/Stop intents.
- Ensure intent writes trigger kind-specific reload.

### Phase 4 - Quick Add + Daily Progress Widget

- Implement stats summary view.
- Add preset quick-add intent.
- Add deep link to quick capture scene.

### Phase 5 - Stabilization

- Validate cold-launch behavior and stale timeline edge cases.
- Test rapid interactions (multi-click completion/start/stop).
- Validate behavior when app is not running.

## Acceptance Criteria

- Users can complete at least one visible task directly from Today widget.
- Users can start and stop focus from widget without opening main UI.
- Users can add a new preset task from widget in one action.
- Widget data remains consistent with app state after every interaction.
- Widget timelines update within expected refresh windows after writes.

## Optional V2 Extensions

- Dedicated large "Weekly Insights" widget.
- Configurable task source (Today, High Priority, Custom category).
- Configurable focus profile per widget instance.

## Apple References

- WidgetKit overview: https://developer.apple.com/documentation/widgetkit
- Creating a widget extension: https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension
- Widget interactivity with App Intents: https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities
- Keeping widgets up to date: https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date