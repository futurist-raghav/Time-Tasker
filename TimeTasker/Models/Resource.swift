import Foundation
import AppKit

enum ResourceType: String, Codable {
    case application
    case file
    case website
}

struct Resource: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var path: String
    var type: ResourceType

    init(id: UUID = UUID(), name: String, path: String, type: ResourceType) {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
    }

    static func == (lhs: Resource, rhs: Resource) -> Bool {
        lhs.path == rhs.path
    }
}
