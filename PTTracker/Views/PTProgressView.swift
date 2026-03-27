import SwiftUI
import SwiftData

struct PTProgressView: View {
    @Query(sort: \Track.sortOrder) private var tracks: [Track]

    private var activeLevels: [Level] {
        ProgressionEngine.activeLevels(tracks: tracks)
    }

    var body: some View {
        NavigationStack {
            List {
                if !activeLevels.isEmpty {
                    Section("Current Batch") {
                        ForEach(activeLevels, id: \.persistentModelID) { level in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(level.displayName)
                                    .font(.headline)
                                ForEach(level.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.persistentModelID) { exercise in
                                    ExerciseProgressRow(
                                        name: exercise.name,
                                        currentDuration: exercise.currentDuration
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("All Tracks") {
                    ForEach(tracks, id: \.persistentModelID) { track in
                        let completed = track.levels.filter(\.isComplete).count
                        let total = track.levels.count
                        HStack {
                            Text(track.name)
                            Spacer()
                            Text("\(completed)/\(total) levels")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }
}
