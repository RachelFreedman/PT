import SwiftUI
import SwiftData

struct TrackDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Track.sortOrder) private var tracks: [Track]
    let trackID: PersistentIdentifier

    private var track: Track? {
        modelContext.model(for: trackID) as? Track
    }

    private var activeLevelIDs: Set<PersistentIdentifier> {
        Set(ProgressionEngine.activeLevels(tracks: tracks).map(\.persistentModelID))
    }

    var body: some View {
        Group {
            if let track {
                List(track.levels.sorted(by: { $0.levelNumber < $1.levelNumber }), id: \.persistentModelID) { level in
                    NavigationLink(value: LevelNavID(id: level.persistentModelID)) {
                        HStack(spacing: 12) {
                            levelIndicator(for: level)
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.displayName)
                                    .font(.subheadline.weight(.medium))
                                Text(levelStatus(for: level))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .navigationTitle(track.name)
            } else {
                ContentUnavailableView("Not found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func levelIndicator(for level: Level) -> some View {
        let done = level.exercises.filter(\.isComplete).count
        let total = level.exercises.count
        let progress = total > 0 ? Double(done) / Double(total) : 0

        if level.isComplete {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.15))
                Image(systemName: "checkmark")
                    .font(.caption2.bold())
                    .foregroundStyle(Theme.accent)
            }
        } else if activeLevelIDs.contains(level.persistentModelID) {
            CircularProgressView(progress: progress, color: Theme.accent)
        } else {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
        }
    }

    private func levelStatus(for level: Level) -> String {
        if level.isComplete {
            return "Complete"
        } else if activeLevelIDs.contains(level.persistentModelID) {
            let done = level.exercises.filter(\.isComplete).count
            let total = level.exercises.count
            return "\(done)/\(total) exercises"
        } else {
            return "Not started"
        }
    }
}
