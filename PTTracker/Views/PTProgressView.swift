import SwiftUI
import SwiftData

struct TrackNavID: Hashable {
    let id: PersistentIdentifier
}

struct LevelNavID: Hashable {
    let id: PersistentIdentifier
}

struct PTProgressView: View {
    @Query(sort: \Track.sortOrder) private var tracks: [Track]
    @Query(sort: \DayLog.date) private var dayLogs: [DayLog]

    private var activeLevels: [Level] {
        ProgressionEngine.activeLevels(tracks: tracks)
    }

    private var currentBatchLevel: Int {
        (ProgressionEngine.currentBatchNumber(tracks: tracks) ?? 0) + 1
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProgressChartView(dayLogs: dayLogs)
                        .listRowInsets(EdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8))
                        .listRowBackground(Color.clear)
                }

                if !activeLevels.isEmpty {
                    Section {
                        ForEach(activeLevels, id: \.persistentModelID) { level in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(level.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.batchColor(for: currentBatchLevel))
                                ForEach(level.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.persistentModelID) { exercise in
                                    ExerciseProgressRow(exercise: exercise, accentColor: Theme.batchColor(for: currentBatchLevel))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Current Batch")
                    }
                }

                Section {
                    ForEach(tracks, id: \.persistentModelID) { track in
                        NavigationLink(value: TrackNavID(id: track.persistentModelID)) {
                            HStack(spacing: 12) {
                                let completed = track.levels.filter(\.isComplete).count
                                let total = track.levels.count
                                let progress = total > 0 ? Double(completed) / Double(total) : 0

                                CircularProgressView(progress: progress, color: trackColor(for: track.name))
                                    .frame(width: 32, height: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.name)
                                        .font(.subheadline.weight(.medium))
                                    Text("\(completed)/\(total) levels")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("All Tracks")
                }
            }
            .navigationTitle("Progress")
            .navigationDestination(for: TrackNavID.self) { nav in
                TrackDetailView(trackID: nav.id)
            }
            .navigationDestination(for: LevelNavID.self) { nav in
                LevelDetailView(levelID: nav.id)
            }
        }
    }

    private func trackColor(for name: String) -> Color {
        switch name {
        case "Mat":              return Theme.gradientColor(at: 0.0)
        case "Ball":             return Theme.gradientColor(at: 0.15)
        case "Neck":             return Theme.gradientColor(at: 0.45)
        case "Lower Extremity":  return Theme.gradientColor(at: 0.85)
        default:                 return Theme.accent
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress >= 1.0 {
                Image(systemName: "checkmark")
                    .font(.caption2.bold())
                    .foregroundStyle(color)
            }
        }
    }
}
