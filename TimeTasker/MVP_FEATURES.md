# Time Tasker's - Minimum Viable Product Features

**Version**: 4.5  
**Platform**: macOS (Apple Silicon only, arm64)  
**Purpose**: Distraction-blocking productivity application for focused work sessions

---

## 📋 **Core Features**

### 1. Task Management
[x] **Create Tasks** with title, deadline date, and deadline time
[x] **Task Priority Ordering** - Drag-and-drop to reorder task queue
[x] **Active Task Tracking** - Select and activate one task at a time
[x] **Task Deletion** - Remove completed or unwanted tasks (Move to completed task page)
[x] **Task Status** - Visual indicators for:
  - Active tasks (green highlight with 🎯 indicator)
  - Expired deadlines (EXPIRED label) [User can Restart task]
  - Time remaining countdown timer
[x] **Task Queue Display** - Shows all tasks in priority order with resource counts
[x] **Task Priority** - Assign priority levels (Low, Medium, High, Urgent) with color coding
[x] **Task Notes** - Add optional notes/details to tasks for better context
[x] **Task Completion** - Mark tasks as complete with dedicated complete button
[x] **Task History** - View all completed tasks with timestamps and focus time spent

### 2. Deadline Management
[x] **Date Picker** - Select deadline date from calendar
[x] **Time Picker** - Set specific deadline time with hour/minute selector
[x] **Current Time Display** - Large formatted clock showing real-time (enhanced size)
[x] **Countdown Timers** - Per-task remaining time display with formatting:
  - Shows days if deadline > 24 hours away
  - Shows hours:minutes:seconds format
  - Updates every second
[x] **Expiration Alerts** - Notification when task deadline passes with options to:
  - Continue working on task
  - Auto-advance to next task

### 3. Category-Based Task Organization
[x] **5 Predefined Categories**:
  - **Coding**: Xcode, Visual Studio Code, Terminal, iTerm, Sublime Text, IntelliJ IDEA, PyCharm, WebStorm, Cursor
  - **Writing**: Pages, Microsoft Word, Google Chrome, Safari, Notion, Bear, Ulysses, Notes
  - **Design**: Figma, Sketch, Adobe Photoshop, Adobe Illustrator, Affinity Designer, Canva
  - **Research**: Safari, Google Chrome, Firefox, Microsoft Edge, Notes, Preview, Books
  - **Custom**: User-defined category with manual app selection
[x] **Category Icons** - Visual indicators for quick category identification
[x] **Auto-Load Defaults** - Selecting a category automatically loads default allowed apps
[x] **Custom Additions** - Add apps beyond default list for any category

### 4. Application Whitelisting & Blocking System

#### Resource Management
[x] **Per-Task Resources** - Each task maintains its own whitelist of allowed apps and files
[x] **Temporary Staging** - Resources are staged during task creation, then finalized
[x] **Resource List Display** - Shows count of allowed resources per task
[x] **App Picker** - Searchable interface for selecting apps to allow
  - Searches `/Applications` folder
  - Searches `~/Applications` folder
  - Shows app icons and names
  - Filter/search functionality
[ ] **File Picker** - Select specific files allowed during task work
[x] **Duplicate Prevention** - Cannot add the same app or file twice to a task
[x] **Resource Removal** - Delete individual resources before creating task

#### Application Blocking Enforcement
[x] **Real-Time Monitoring** - Detects when user switches to any application
[x] **Automatic Enforcement**:
  [x] Terminates non-allowed applications
  [x] Shows alert popup identifying blocked app
  [x] Auto-refocuses Time Tasker to foreground
  [x] 300ms delay before enforcement (prevents false positives)
[x] **System App Protection** - Always allows:
  [x] Finder
  [x] System Settings
  [x] System Preferences
  [x] Other critical system apps
[x] **Self Protection** - Time Tasker always allowed to run
[x] **Per-Task Whitelisting** - Only apps in active task's resource list are permitted

### 5. Task Activation & Focus Mode

#### Starting a Task
[x] **Start Button** - Click to activate any task in queue
[x] **Auto-Focus** - App brings itself to foreground when starting
[x] **Global Whitelist Update** - Allowed app list updates to only include active task's resources
[x] **First Task Auto-Start** - If no tasks exist and you create one, it auto-starts

#### Active Task Display
[x] **Prominent Highlighting** - Large green-highlighted section at top of task list
[x] **Task Title** - Large bold text showing current focus task
[x] **Remaining Time** - Large countdown timer showing time left
[x] **Allowed Apps List** - Shows which apps are permitted during this session
[x] **Stop Button** - End focus session and return to normal mode
#### Stopping a Task
[x] **Stop Button** - Click to deactivate current task
[x] **Auto-Next** - Optionally auto-advance to next task in queue
[ ] **Auto-Delete** - Option to remove completed task
[x] **Whitelist Reset** - Global allowed app list clears when stopping

### 6. Music Player
[x] **Add Audio Files** - File picker to add MP3 and audio files
[x] **Playback Controls**:
  [x] Play/Pause toggle
  [x] Next song button
  [x] Previous song button
  [x] Rewind 5 seconds
  [x] Forward 5 seconds
[x] **Song Information** - Display current song filename
[x] **Playlist Management** - Build queue of audio files
[x] **No App Switching** - Music plays within Time Tasker (no need for Spotify/Apple Music)
[x] **Keyboard Shortcuts**:
  [x] `Space` - Play/Pause
  [x] `←` (Left Arrow) - Rewind 5 seconds
  [x] `→` (Right Arrow) - Forward 5 seconds
  [x] `Cmd+P` - Previous song
  [x] `Cmd+N` - Next song

### 7. User Interface & Experience

#### Layout & Design
[x] **Minimal Single-Page UI** - All Main features on one screen to minimize distractions
[x] **Layout**: Think and create best UI/UX accordingly that maximise productivity and ease of use.
[x] **Dark/Light Mode Support** - Adapts to system appearance settings with manual override option
[x] **Liquid Glass Visual Theme** - Material-based translucent surfaces and depth-forward cards across primary screens
[x] **Menu bar + Pop Up page** - For extra non important features like complete task list, settings, About Developer, About app, etc.
[x] **Calendar View** - Visual deadline calendar for task overview
[x] **Clean Typography** - Large readable fonts for minimum eye strain
[x] **Color-Coded Status**:
  [x] Green for active/allowed
  [x] Red for blocked/stop actions
  [x] Blue for primary actions
  [x] Gray for disabled/secondary

#### Visual Feedback
[x] **Task Row Display** - Shows:
  [x] Task title
  [x] Deadline time remaining
  [x] Category with icon
  [x] Resource count badge
  [x] Delete button
  [x] Priority indicator (color-coded)
  [x] Complete button
[ ] **Drag-to-Reorder Indicator** - Visual feedback when reordering tasks
[x] **Button States** - Disabled buttons when not applicable (e.g., Add Task when title empty)
[x] **Alert Popups** - Informative messages for:
  [x] Blocked app notifications
  [x] Task expiration
  [ ] Confirmation dialogs

#### Input Forms
[x] **Text Fields** - Single-line entry for task titles
[x] **Date/Time Pickers** - Popover-based selection for deadlines
[x] **Category Picker** - Popover dropdown for category selection
[x] **Priority Picker** - Popover dropdown for priority selection
[x] **Notes Field** - Multi-line text area for task notes
[x] **Searchable App Picker** - Filter and select from system applications
[x] **File Importer** - Standard macOS file selection dialog

### 8. Task History & Analytics

#### Task History
[x] **Completed Tasks View** - Dedicated page showing all completed tasks
[x] **Completion Timestamp** - Shows when each task was completed
[x] **Focus Time Tracking** - Displays actual time spent on each completed task
[x] **Success Indicator** - Visual indicator for tasks completed before deadline
[x] **Category Display** - Shows category of completed tasks
[x] **Restore Task** - Option to restore completed task back to active queue
[x] **Delete from History** - Option to permanently remove task from history
[x] **Clear All History** - Button to clear entire task history
[x] **Persistent Storage** - History saved to UserDefaults

#### Analytics Dashboard
[x] **Total Tasks Completed** - Running count of all completed tasks
[x] **Total Focus Time** - Cumulative time spent in focus mode
[x] **Average Task Duration** - Average time spent per completed task
[x] **Category Breakdown** - Visual chart showing task distribution by category
[x] **Time Formatting** - Hours/minutes display for time metrics
[x] **Empty State** - Informative message when no data available

---

## 🔒 **System Integration & Permissions**

### macOS Capabilities Required
[x] **Sandbox** - App runs in restricted sandbox environment
[x] **File Access** - User-selected read/write access to files
[x] **Audio** - Permission to read and play audio files
[x] **App Monitoring** - NSWorkspace notifications for application activation
[x] **Process Termination** - Ability to terminate non-allowed applications

### Privacy & Accessibility
[x] **No Data Collection** - All tasks and data stored locally
[x] **No Network Required** - Fully offline operation
[x] **No Cloud Sync** - Tasks persist on device only

---

## ⚙️ **Technical Features**

### Memory Management
[x] **Timer Lifecycle** - Timers properly created and invalidated to prevent leaks
[x] **Observer Cleanup** - NSWorkspace observers removed on app termination
[x] **Resource Cleanup** - Temporary resources cleared after task creation
[x] **State Management** - Proper @State and @StateObject usage

### Performance
[x] **Real-Time Responsiveness** - <100ms app blocking reaction time
[x] **Efficient Monitoring** - Single NSWorkspace observer for all app detection
[x] **Optimized UI Updates** - Only relevant components refresh on state changes
[x] **Smooth Animations** - Drag-to-reorder with visual feedback

### Data Management
[x] **Per-Task Isolation** - Resources don't leak between tasks
[x] **Duplicate Prevention** - No duplicate apps or files in resource lists
[x] **Type Safety** - Struct-based models with proper identification
[x] **Identifiable Resources** - UUID-based resource identification
[x] **Persistent Task History** - Completed tasks saved to UserDefaults
[x] **Analytics Calculations** - Real-time computed analytics from history data

---

## 🎯 **Use Cases & Workflows**

### Workflow 1: Focused Coding Session
1. Create task: "Finish API implementation"
2. Select category: "Coding" (auto-loads Xcode, VS Code, Terminal, etc.)
3. Set priority: "High"
4. Add deadline: Today at 5:00 PM
5. Optionally add custom apps (e.g., documentation website)
6. Click "Add Task"
7. Task auto-starts → Coding tools whitelisted → All other apps blocked

### Workflow 2: Writing Sprint with Music
1. Create task: "Write blog post outline"
2. Select category: "Writing"
3. Set deadline: 2 hours from now
4. Add tasks to queue
5. Start task → Music player ready in interface
6. Add audio files for focus music
7. Play music while writing → No need to switch apps

### Workflow 3: Priority-Based Task Management
1. Create multiple tasks with different deadlines and priorities
2. Drag-to-reorder tasks by priority
3. Start highest priority task
4. When task expires → Notification prompts next task
5. Click "Continue to Next" → Auto-advance to next priority task

### Workflow 4: Custom Task with Specific Resources
1. Select "Custom" category
2. Manually add specific apps (e.g., IDE, documentation, Stack Overflow)
3. Add specific files (research documents, reference PDFs)
4. Create task → Only those exact apps/files allowed

### Workflow 5: Task Completion & Review
1. Complete a task by clicking the checkmark button
2. Task moves to Task History with completion timestamp
3. View Analytics to see productivity metrics
4. Review category breakdown to understand time allocation
5. Restore tasks from history if needed

---

## 📊 **Key Metrics & Information Displayed**

### Time Information
- Current real-time clock (updated every second, enhanced size)
- Per-task time remaining (dynamic countdown)
- Days, hours, minutes, seconds formatting
- Deadline date and time
- Total focus time spent (analytics)
- Average task duration (analytics)

### Task Information
- Task count in queue
- Priority position (1st, 2nd, etc.)
- Category assignment
- Number of allowed resources per task
- Task title/description
- Task priority level with color indicator
- Task notes/details
- Completion status

### Resource Information
- Count of allowed apps per task
- Count of allowed files per task
- Resource type indicators (app icon, file icon)
- Resource list for active task

### Analytics Information
- Total tasks completed
- Total focus time
- Average task duration
- Category distribution

---

## 🛡️ **Safety & Constraints**

### App Blocking Safety
- System apps always permitted (can't block Finder, System Settings)
- Time Tasker cannot be blocked (always running)
- 300ms delay before enforcement (allows app launch completion)
- Clear alerts showing which app was blocked and why

### Data Integrity
- Tasks stored in memory (@State array)
- Task history persisted to UserDefaults
- Changes persist during app session
- Task queue maintains order across edits
- No data loss on task modifications

### User Control
- Can stop any active task at any time
- Can delete any task
- Can reorder tasks freely
- Can stop blocking enforcement by stopping task
- No forced focus mode (user in control)
- Can restore tasks from history
- Can clear task history

---

## ✨ **Distinguishing Features**

### Compared to Traditional To-Do Apps
- ✅ **Active blocking** - Not just reminders, actively prevents distractions
- ✅ **Category-based** - Smart defaults reduce setup time
- ✅ **Per-task resources** - Different tasks can have different allowed apps
- ✅ **Priority system** - Visual priority indicators for task urgency
- ✅ **Built-in analytics** - Track productivity without external tools

### Compared to Website Blockers
- ✅ **Application-level** - Blocks entire apps, not just websites
- ✅ **Task-integrated** - Blocking tied to task deadlines and priorities
- ✅ **System-wide** - Works across all applications, not browser-limited

### Compared to Time Trackers
- ✅ **Proactive** - Prevents distraction before it happens
- ✅ **Enforced** - Doesn't just track, actively blocks
- ✅ **Focus-first** - UI designed for minimal distraction
- ✅ **Completion tracking** - Automatic time tracking on task completion

### What Makes This App Unique

### Compared to Traditional To-Do Apps
❌ **Traditional apps**: Just show tasks, user must self-discipline
✅ **Time Tasker's**: Actively prevents distraction by blocking apps

### Compared to Website Blockers
❌ **Website blockers**: Only block websites (Freedom, Cold Turkey)
✅ **Time Tasker's**: Blocks entire applications system-wide

### Compared to Time Trackers
❌ **Time trackers**: Track what you did, but don't prevent distractions
✅ **Time Tasker's**: Proactively enforces focus before distraction happens

### The "Minimal UI" Philosophy
- **Single window**: Everything on one screen
- **No tabs/navigation**: Reduces cognitive load
- **Built-in music**: No need to Alt+Tab to Spotify
- **Built-in analytics**: No external tracking apps needed
- **No fancy animations**: Fast, functional, distraction-free


---

## 📱 **Supported Platforms & Requirements**

- **Platform**: macOS
- **Minimum macOS Version**: 14.0+
- **Framework**: SwiftUI + AVFoundation
- **Architecture**: ARM64 (Apple Silicon) and x86_64 (Intel)

---

## 🔄 **App Lifecycle**

### Launch
1. App initializes with empty task list
2. Task history loaded from UserDefaults
3. Music player ready
4. NSWorkspace monitoring starts
5. No active task initially

### During Focus Session
1. Task active → monitoring enabled
2. NSWorkspace detects app switches
3. Non-allowed apps → alert + terminate
4. Task timer counts down
5. At deadline → expiration alert

### Task Completion
1. User completes task (checkmark button) OR stops task OR deadline expires
2. Completed tasks → saved to Task History with focus time
3. Optional: Auto-advance to next task
4. Whitelisting returns to unrestricted
5. Ready for next focus session

### App Exit
1. Active task stopped
2. Task history saved to UserDefaults
3. NSWorkspace observer removed
4. Timers invalidated
5. Clean shutdown

---

## 🎨 **Visual Design Elements**

- **Color Scheme**: System-aware (Light/Dark mode support)
- **Typography**: San Francisco font family
- **Spacing**: 10-point baseline grid
- **Corners**: 8-point border radius for cards
- **Icons**: SF Symbols throughout
- **Priority Colors**: Gray (Low), Blue (Medium), Orange (High), Red (Urgent)
- **Accessibility**: Full VoiceOver support, high contrast options

---
