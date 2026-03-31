import Foundation
import SwiftData

@Model
final class DayLog {
    var date: Date
    var isSkip: Bool
    var skipReason: String?
    var batchNumber: Int
    var wellnessScore: Int?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.dayLog)
    var exerciseLogs: [ExerciseLog] = []

    init(date: Date, isSkip: Bool, skipReason: String? = nil, batchNumber: Int = 0, wellnessScore: Int? = nil) {
        self.date = date
        self.isSkip = isSkip
        self.skipReason = skipReason
        self.batchNumber = batchNumber
        self.wellnessScore = wellnessScore
    }
}

enum WellnessScale {
    static let labels: [Int: String] = [
        0: "Completely normal",
        1: "Overall feeling well",
        2: "Minimal feeling unwell",
        3: "Mild feeling unwell",
        4: "Feeling unwell but still functioning",
        5: "Uncomfortable but can function if must",
        6: "Very difficult to function",
        7: "Can't function",
        8: "Very sick and distressed",
        9: "Extremely sick and distressed",
        10: "Worst ever",
    ]

    static func label(for score: Int) -> String {
        labels[score] ?? "\(score)"
    }
}
