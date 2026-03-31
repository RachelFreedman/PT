import SwiftUI
import SwiftData

struct CurrentBatchSummary: View {
    @Query(sort: \Track.sortOrder) private var tracks: [Track]

    private var activeLevels: [Level] {
        ProgressionEngine.activeLevels(tracks: tracks)
    }

    var body: some View {
        if activeLevels.isEmpty {
            Label("Program complete!", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundStyle(Theme.gradient)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current batch")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(activeLevels.map(\.displayName).joined(separator: " + "))
                    .font(.headline)
            }
        }
    }
}
