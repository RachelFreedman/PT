import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var sortOrder: Int
    var currentDuration: Int
    var startDuration: Int
    var targetMaxDuration: Int
    var perSessionIncrement: Int
    var level: Level?

    init(
        name: String,
        sortOrder: Int,
        currentDuration: Int = PTProtocolConfig.startDuration,
        targetMaxDuration: Int = PTProtocolConfig.maxDuration,
        perSessionIncrement: Int = PTProtocolConfig.durationIncrement
    ) {
        self.name = name
        self.sortOrder = sortOrder
        self.currentDuration = currentDuration
        self.startDuration = currentDuration
        self.targetMaxDuration = targetMaxDuration
        self.perSessionIncrement = perSessionIncrement
    }

    var isComplete: Bool {
        currentDuration >= targetMaxDuration
    }
}
