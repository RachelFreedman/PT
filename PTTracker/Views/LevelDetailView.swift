import SwiftUI
import SwiftData

struct LevelDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Track.sortOrder) private var tracks: [Track]
    let levelID: PersistentIdentifier

    private var level: Level? {
        modelContext.model(for: levelID) as? Level
    }

    private var currentBatchLevel: Int {
        (ProgressionEngine.currentBatchNumber(tracks: tracks) ?? 0) + 1
    }

    var body: some View {
        Group {
            if let level {
                let color = level.isComplete ? Theme.accent : Theme.batchColor(for: currentBatchLevel)
                List {
                    Section {
                        let done = level.exercises.filter(\.isComplete).count
                        let total = level.exercises.count
                        HStack {
                            CircularProgressView(progress: total > 0 ? Double(done) / Double(total) : 0, color: color)
                                .frame(width: 36, height: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.isComplete ? "Complete" : "\(done)/\(total) at target")
                                    .font(.subheadline.weight(.medium))
                                Text(level.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Exercises") {
                        ForEach(level.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.persistentModelID) { exercise in
                            ExerciseProgressRow(exercise: exercise, accentColor: color)
                        }
                    }
                }
                .navigationTitle(level.displayName)
            } else {
                ContentUnavailableView("Not found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
