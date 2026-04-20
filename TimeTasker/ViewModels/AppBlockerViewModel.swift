import Foundation
import Combine

class AppBlockerViewModel: ObservableObject {
    private let monitorService = AppMonitorService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isMonitoring: Bool = false
    @Published var blockedAppName: String = ""
    @Published var blockedAppsCount: Int = 0
    @Published var blockedWebsitesCount: Int = 0
    @Published var blockedItemsCount: Int = 0
    @Published var websiteEnforcementMode: WebsiteEnforcementMode = .inactive

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
        
        monitorService.$blockedApps
            .receive(on: DispatchQueue.main)
            .map { $0.count }
            .assign(to: &$blockedAppsCount)
        
        monitorService.$blockedWebsites
            .receive(on: DispatchQueue.main)
            .map { $0.count }
            .assign(to: &$blockedWebsitesCount)

        monitorService.$websiteEnforcementMode
            .receive(on: DispatchQueue.main)
            .assign(to: &$websiteEnforcementMode)
        
        Publishers.CombineLatest(monitorService.$blockedApps, monitorService.$blockedWebsites)
            .receive(on: DispatchQueue.main)
            .map { $0.count + $1.count }
            .assign(to: &$blockedItemsCount)
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
        let appCount = task.resources.filter { $0.type == .application }.count
        let websiteCount = task.resources.filter { $0.type == .website }.count
        print("🛡️ Starting blocking for task: \(task.title) with \(appCount) blocked apps and \(websiteCount) blocked websites")
        monitorService.startMonitoring(with: task.resources)
    }

    private func stopBlocking() {
        print("🛡️ Stopping blocking")
        monitorService.stopMonitoring()
    }
}
