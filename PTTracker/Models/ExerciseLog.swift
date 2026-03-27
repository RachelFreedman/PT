import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var exerciseName: String
    var durationUsed: Int
    var completed: Bool
    var dayLog: DayLog?

    init(exerciseName: String, durationUsed: Int, completed: Bool = false) {
        self.exerciseName = exerciseName
        self.durationUsed = durationUsed
        self.completed = completed
    }
}
