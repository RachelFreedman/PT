import Foundation
import SwiftData

enum ProgressionEngine {

    /// Returns the current batch number — the lowest batch index where any level is still incomplete.
    /// Returns nil if the entire program is complete.
    static func currentBatchNumber(tracks: [Track]) -> Int? {
        for (index, batch) in BatchConfig.batches.enumerated() {
            let allComplete = batch.allSatisfy { entry in
                guard let level = findLevel(trackName: entry.trackName, levelNumber: entry.levelNumber, in: tracks) else {
                    return true // track/level not found — treat as vacuously complete
                }
                return level.isComplete
            }
            if !allComplete {
                return index
            }
        }
        return nil // all batches complete
    }

    /// Returns the active levels for the current batch.
    static func activeLevels(tracks: [Track]) -> [Level] {
        guard let batchNum = currentBatchNumber(tracks: tracks) else { return [] }
        let batch = BatchConfig.batches[batchNum]
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

    /// Advance durations for completed exercises. Each gains +10s, capped at 180.
    static func advanceDurations(for exercises: [Exercise]) {
        for exercise in exercises {
            exercise.currentDuration = min(exercise.currentDuration + 10, 180)
        }
    }

    /// Returns true if the entire PT program is complete (all batches done).
    static func isProgramComplete(tracks: [Track]) -> Bool {
        currentBatchNumber(tracks: tracks) == nil
    }

    /// Returns true if the current batch just became complete (all levels at 180s).
    static func isBatchComplete(tracks: [Track]) -> Bool {
        guard let batchNum = currentBatchNumber(tracks: tracks) else { return false }
        let batch = BatchConfig.batches[batchNum]
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
