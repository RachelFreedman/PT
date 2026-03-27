import Foundation

enum BatchConfig {
    struct TrackDefinition {
        let name: String
        let levelCount: Int
    }

    struct BatchEntry {
        let trackName: String
        let levelNumber: Int
    }

    static let trackDefinitions: [TrackDefinition] = [
        TrackDefinition(name: "Mat", levelCount: 5),
        TrackDefinition(name: "Ball", levelCount: 5),
    ]

    /// Staggered batch schedule:
    /// Batch 0: Mat L0
    /// Batch 1: Mat L1 + Ball L0
    /// Batch 2: Mat L2 + Ball L1
    /// Batch 3: Mat L3 + Ball L2
    /// Batch 4: Mat L4 + Ball L3
    /// Batch 5: Ball L4
    static let batches: [[BatchEntry]] = [
        [BatchEntry(trackName: "Mat", levelNumber: 0)],
        [BatchEntry(trackName: "Mat", levelNumber: 1), BatchEntry(trackName: "Ball", levelNumber: 0)],
        [BatchEntry(trackName: "Mat", levelNumber: 2), BatchEntry(trackName: "Ball", levelNumber: 1)],
        [BatchEntry(trackName: "Mat", levelNumber: 3), BatchEntry(trackName: "Ball", levelNumber: 2)],
        [BatchEntry(trackName: "Mat", levelNumber: 4), BatchEntry(trackName: "Ball", levelNumber: 3)],
        [BatchEntry(trackName: "Ball", levelNumber: 4)],
    ]
}
