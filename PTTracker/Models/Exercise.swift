import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var sortOrder: Int
    var currentDuration: Int
    var level: Level?

    init(name: String, sortOrder: Int, currentDuration: Int = 90) {
        self.name = name
        self.sortOrder = sortOrder
        self.currentDuration = currentDuration
    }
}
