import Foundation
import SwiftData

enum DataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Track>()
        let existingTracks = (try? context.fetch(descriptor)) ?? []
        guard existingTracks.isEmpty else { return }

        for (index, def) in BatchConfig.trackDefinitions.enumerated() {
            let track = Track(name: def.name, sortOrder: index)
            for levelNum in 0..<def.levelCount {
                let level = Level(levelNumber: levelNum)
                for exNum in 0..<3 {
                    let exercise = Exercise(
                        name: "\(def.name) L\(levelNum) Ex\(exNum)",
                        sortOrder: exNum
                    )
                    level.exercises.append(exercise)
                }
                track.levels.append(level)
            }
            context.insert(track)
        }
        try? context.save()
    }
}
