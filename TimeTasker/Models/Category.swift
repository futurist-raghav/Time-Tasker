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

    var defaultApps: [String] {
        switch self {
        case .coding:
            return ["Xcode", "Visual Studio Code", "Terminal", "iTerm", "Cursor", "Sublime Text", "IntelliJ IDEA", "PyCharm", "WebStorm"]
        case .writing:
            return ["Pages", "Microsoft Word", "Google Chrome", "Safari", "Notion", "Bear", "Ulysses", "Notes"]
        case .design:
            return ["Figma", "Sketch", "Adobe Photoshop", "Adobe Illustrator", "Affinity Designer", "Canva"]
        case .research:
            return ["Safari", "Google Chrome", "Firefox", "Microsoft Edge", "Notes", "Preview", "Books"]
        case .custom:
            return []
        }
    }
}
