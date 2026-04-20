import Foundation

enum Category: String, Codable, CaseIterable {
    case coding = "Coding"
    case writing = "Writing"
    case design = "Design"
    case research = "Research"
    case custom = "Custom"

    var iconName: String {
        switch self {
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .writing: return "doc.text"
        case .design: return "paintbrush"
        case .research: return "magnifyingglass"
        case .custom: return "gearshape"
        }
    }

    var defaultBlockedApps: [String] {
        switch self {
        case .coding:
            return ["Safari", "Google Chrome", "Comet", "Arc", "Discord", "Slack", "Messages"]
        case .writing:
            return ["YouTube Music", "Discord", "Messages", "Steam", "X"]
        case .design:
            return ["Discord", "Messages", "Steam", "Safari", "Google Chrome"]
        case .research:
            return ["Discord", "Messages", "Steam", "X", "Instagram"]
        case .custom:
            return []
        }
    }
    
    var defaultApps: [String] {
        defaultBlockedApps
    }
}
