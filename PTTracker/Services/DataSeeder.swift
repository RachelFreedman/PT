import Foundation
import SwiftData

enum DataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Track>()
        let existingTracks = (try? context.fetch(descriptor)) ?? []
        guard existingTracks.isEmpty else { return }

        for (trackIndex, trackDef) in PTProtocolConfig.tracks.enumerated() {
            let track = Track(name: trackDef.name, sortOrder: trackIndex)
            for (levelNum, levelDef) in trackDef.levels.enumerated() {
                let level = Level(levelNumber: levelNum)
                for (exIndex, exDef) in levelDef.exercises.enumerated() {
                    let exercise = Exercise(
                        name: exDef.name,
                        sortOrder: exIndex,
                        currentDuration: exDef.resolvedStartDuration,
                        targetMaxDuration: exDef.resolvedMaxDuration,
                        perSessionIncrement: exDef.resolvedDurationIncrement
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
