import Foundation
import SwiftData

enum ProgressionEngine {

    /// Minimum remaining seconds at which a "skip" still counts as completed.
    static let skipGraceSeconds: Int = 20

    /// Days without a workout before the last workout must be repeated (no increment).
    static let repeatAfterDays: Int = 3

    /// Days without a workout before the entire batch resets to start durations.
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
        /// Repeat workout — do not advance durations afterward (gap of 3+ days).
        case repeatAfterGap
        /// Partial redo — only the incomplete exercises from last time, at the same durations. No advancement.
        case redoIncomplete
    }

    struct WorkoutPlan {
        let mode: WorkoutMode
        let exercises: [(exercise: Exercise, targetDuration: Int)]
    }

    /// Determines what the next workout should look like based on history.
    static func planWorkout(tracks: [Track], dayLogs: [DayLog]) -> WorkoutPlan {
        let allExercises = activeExercises(tracks: tracks)
        guard !allExercises.isEmpty else {
            return WorkoutPlan(mode: .normal, exercises: [])
        }

        // Find the most recent non-skip workout log
        let lastWorkout = dayLogs
            .filter { !$0.isSkip && !$0.exerciseLogs.isEmpty }
            .sorted { $0.date > $1.date }
            .first

        guard let lastWorkout else {
            // No previous workout — just start normally
            return WorkoutPlan(mode: .normal, exercises: allExercises.map { ($0, $0.currentDuration) })
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastWorkout.date, to: Date.now.startOfDay).day ?? 0

        // 7+ days: reset batch to start durations
        if daysSince >= resetAfterDays {
            resetBatchToStart(tracks: tracks)
            return WorkoutPlan(mode: .repeatAfterGap, exercises: allExercises.map { ($0, $0.currentDuration) })
        }

        // Check if last workout had incomplete exercises
        let incompleteNames = lastWorkout.exerciseLogs
            .filter { !$0.completed }
            .map(\.exerciseName)

        if !incompleteNames.isEmpty {
            // Redo only the incomplete exercises at their current (un-advanced) durations
            let redoExercises = allExercises.filter { incompleteNames.contains($0.name) }
            if !redoExercises.isEmpty {
                return WorkoutPlan(mode: .redoIncomplete, exercises: redoExercises.map { ($0, $0.currentDuration) })
            }
        }

        // 3+ days: repeat the full workout without advancing
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
