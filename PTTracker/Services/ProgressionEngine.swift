import Foundation
import SwiftData

enum ProgressionEngine {

    /// Minimum remaining seconds at which a "skip" still counts as completed.
    static let skipGraceSeconds: Int = 20

    /// Days without a fully completed workout before repeating (no advancement).
    static let repeatAfterDays: Int = 3

    /// Days without a fully completed workout before resetting the batch.
    static let resetAfterDays: Int = 7

    // MARK: - Batch & Level Queries

    /// Returns the current batch number — the lowest batch index where any level is still incomplete.
    /// Returns nil if the entire program is complete.
    static func currentBatchNumber(tracks: [Track]) -> Int? {
        for (index, batch) in PTProtocolConfig.batches.enumerated() {
            let allComplete = batch.allSatisfy { entry in
                guard let level = findLevel(trackName: entry.trackName, levelNumber: entry.levelNumber, in: tracks) else {
                    return true
                }
                return level.isComplete
            }
            if !allComplete {
                return index
            }
        }
        return nil
    }

    /// Returns the active levels for the current batch.
    static func activeLevels(tracks: [Track]) -> [Level] {
        guard let batchNum = currentBatchNumber(tracks: tracks) else { return [] }
        let batch = PTProtocolConfig.batches[batchNum]
        return batch.compactMap { entry in
            findLevel(trackName: entry.trackName, levelNumber: entry.levelNumber, in: tracks)
        }
    }

    /// Returns the active exercises (sorted by track order, then exercise order) for the current batch.
    static func activeExercises(tracks: [Track]) -> [Exercise] {
        activeLevels(tracks: tracks)
            .sorted { level1, level2 in
                (level1.track?.sortOrder ?? 0) < (level2.track?.sortOrder ?? 0)
            }
            .flatMap { level in
                level.exercises.sorted { $0.sortOrder < $1.sortOrder }
            }
    }

    // MARK: - Workout Planning

    enum WorkoutMode {
        /// Normal workout — advance durations for completed exercises afterward.
        case normal
        /// Repeat workout — same exercises at current durations, no advancement afterward.
        case repeatAfterGap
    }

    struct WorkoutPlan {
        let mode: WorkoutMode
        let exercises: [(exercise: Exercise, targetDuration: Int)]
    }

    /// Determines what the next workout should look like based on history.
    ///
    /// Rules:
    /// - Find the last fully completed workout (all exercises marked completed).
    /// - If >= 7 days since that workout: reset batch to start durations, then repeat.
    /// - If >= 3 days since that workout: repeat at current durations (no advancement).
    ///   This includes days with no log, logged skips, or partial workouts.
    /// - Otherwise: normal workout with advancement.
    static func planWorkout(tracks: [Track], dayLogs: [DayLog]) -> WorkoutPlan {
        let allExercises = activeExercises(tracks: tracks)
        guard !allExercises.isEmpty else {
            return WorkoutPlan(mode: .normal, exercises: [])
        }

        // Find the most recent fully completed workout
        // (non-skip, has exercise logs, and ALL exercises were completed)
        let lastFullWorkout = dayLogs
            .filter { !$0.isSkip && !$0.exerciseLogs.isEmpty && $0.exerciseLogs.allSatisfy(\.completed) }
            .sorted { $0.date > $1.date }
            .first

        guard let lastFullWorkout else {
            // No previous fully completed workout — just start normally
            return WorkoutPlan(mode: .normal, exercises: allExercises.map { ($0, $0.currentDuration) })
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastFullWorkout.date, to: Date.now.startOfDay).day ?? 0

        // 7+ days since last full workout: reset batch to start durations
        if daysSince >= resetAfterDays {
            resetBatchToStart(tracks: tracks)
            let refreshed = activeExercises(tracks: tracks)
            return WorkoutPlan(mode: .repeatAfterGap, exercises: refreshed.map { ($0, $0.currentDuration) })
        }

        // 3+ days since last full workout: repeat at current durations
        if daysSince >= repeatAfterDays {
            return WorkoutPlan(mode: .repeatAfterGap, exercises: allExercises.map { ($0, $0.currentDuration) })
        }

        // Normal workout
        return WorkoutPlan(mode: .normal, exercises: allExercises.map { ($0, $0.currentDuration) })
    }

    /// Resets all exercises in the current batch to their config-defined start durations.
    static func resetBatchToStart(tracks: [Track]) {
        guard let batchNum = currentBatchNumber(tracks: tracks) else { return }
        let batch = PTProtocolConfig.batches[batchNum]
        for entry in batch {
            guard let level = findLevel(trackName: entry.trackName, levelNumber: entry.levelNumber, in: tracks) else { continue }
            guard let trackDef = PTProtocolConfig.tracks.first(where: { $0.name == entry.trackName }) else { continue }
            guard entry.levelNumber < trackDef.levels.count else { continue }
            let levelDef = trackDef.levels[entry.levelNumber]
            for exercise in level.exercises {
                if let exDef = levelDef.exercises.first(where: { $0.name == exercise.name }) {
                    exercise.currentDuration = exDef.resolvedStartDuration
                }
            }
        }
    }

    // MARK: - Advancement

    /// Advance durations for completed exercises using each exercise's own increment and max.
    static func advanceDurations(for exercises: [Exercise]) {
        for exercise in exercises {
            exercise.currentDuration = min(
                exercise.currentDuration + exercise.perSessionIncrement,
                exercise.targetMaxDuration
            )
        }
    }

    /// Returns true if the entire PT program is complete (all batches done).
    static func isProgramComplete(tracks: [Track]) -> Bool {
        currentBatchNumber(tracks: tracks) == nil
    }

    /// Returns true if the current batch just became complete (all levels complete).
    static func isBatchComplete(tracks: [Track]) -> Bool {
        guard let batchNum = currentBatchNumber(tracks: tracks) else { return false }
        let batch = PTProtocolConfig.batches[batchNum]
        return batch.allSatisfy { entry in
            guard let level = findLevel(trackName: entry.trackName, levelNumber: entry.levelNumber, in: tracks) else {
                return true
            }
            return level.isComplete
        }
    }

    // MARK: - Helpers

    private static func findLevel(trackName: String, levelNumber: Int, in tracks: [Track]) -> Level? {
        guard let track = tracks.first(where: { $0.name == trackName }) else { return nil }
        return track.levels.first(where: { $0.levelNumber == levelNumber })
    }
}
