import SwiftUI
import SwiftData

struct CurrentBatchSummary: View {
    @Query(sort: \Track.sortOrder) private var tracks: [Track]

    private var activeLevels: [Level] {
        ProgressionEngine.activeLevels(tracks: tracks)
    }

    var body: some View {
        if activeLevels.isEmpty {
            Text("Program complete!")
                .font(.headline)
                .foregroundStyle(.green)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current batch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(activeLevels.map(\.displayName).joined(separator: " + "))
                    .font(.headline)
            }
        }
    }
}
