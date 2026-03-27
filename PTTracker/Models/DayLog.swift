import Foundation
import SwiftData

@Model
final class DayLog {
    var date: Date
    var isSkip: Bool
    var skipReason: String?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.dayLog)
    var exerciseLogs: [ExerciseLog] = []

    init(date: Date, isSkip: Bool, skipReason: String? = nil) {
        self.date = date
        self.isSkip = isSkip
        self.skipReason = skipReason
    }
}
