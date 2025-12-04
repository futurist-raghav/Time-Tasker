import Foundation
import Combine

class AppBlockerViewModel: ObservableObject {
    private let monitorService = AppMonitorService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isMonitoring: Bool = false
    @Published var blockedAppName: String = ""
    @Published var allowedAppsCount: Int = 0

    init() {
        setupNotifications()
        setupMonitorServiceBindings()
        print("🛡️ AppBlockerViewModel initialized")
    }
    
    private func setupMonitorServiceBindings() {
        // Bind to monitor service state
        monitorService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: &$isMonitoring)
        
        monitorService.$blockedAppName
            .receive(on: DispatchQueue.main)
            .assign(to: &$blockedAppName)
        
        monitorService.$allowedApps
            .receive(on: DispatchQueue.main)
            .map { $0.count }
            .assign(to: &$allowedAppsCount)
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .taskActivated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let task = notification.object as? Task {
                    print("🛡️ Task activated notification received: \(task.title)")
                    self?.startBlocking(for: task)
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .taskStopped)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("🛡️ Task stopped notification received")
                self?.stopBlocking()
            }
            .store(in: &cancellables)
    }

    private func startBlocking(for task: Task) {
        print("🛡️ Starting blocking for task: \(task.title) with \(task.resources.count) allowed apps")
        monitorService.startMonitoring(with: task.resources)
    }

    private func stopBlocking() {
        print("🛡️ Stopping blocking")
        monitorService.stopMonitoring()
    }
}
