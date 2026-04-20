import Foundation
import SwiftData

/// Lightweight snapshot of an in-progress workout, persisted to UserDefaults
/// so it survives app backgrounding or termination.
struct PendingWorkout: Codable {
    let date: Date
    let wellnessScore: Int?
    let workoutMode: String // "normal" or "repeatAfterGap"
    let batchNumber: Int
    var currentExerciseIndex: Int
    var remainingSeconds: Int
    var exercises: [ExerciseSnapshot]

    struct ExerciseSnapshot: Codable {
        let exerciseName: String
        let targetDuration: Int
        var completed: Bool
        var skipped: Bool
    }

    // MARK: - Persistence

    private static let key = "pendingWorkout"

    static func save(_ pending: PendingWorkout) {
        guard let data = try? JSONEncoder().encode(pending) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> PendingWorkout? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PendingWorkout.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Whether this pending workout is from today (still resumable).
    var isFromToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
