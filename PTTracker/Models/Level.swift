import Foundation
import SwiftData

@Model
final class Level {
    var levelNumber: Int
    var track: Track?
    @Relationship(deleteRule: .cascade, inverse: \Exercise.level)
    var exercises: [Exercise] = []

    init(levelNumber: Int) {
        self.levelNumber = levelNumber
    }

    var displayName: String {
        "\(track?.name ?? "?") L\(levelNumber)"
    }

    var isComplete: Bool {
        !exercises.isEmpty && exercises.allSatisfy { $0.isComplete }
    }
}
