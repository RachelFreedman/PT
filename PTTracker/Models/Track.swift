import Foundation
import SwiftData

@Model
final class Track {
    var name: String
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \Level.track)
    var levels: [Level] = []

    init(name: String, sortOrder: Int) {
        self.name = name
        self.sortOrder = sortOrder
    }
}
