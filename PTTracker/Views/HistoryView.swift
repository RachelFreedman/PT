import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayLog.date, order: .reverse) private var dayLogs: [DayLog]
    @Query(sort: \Track.sortOrder) private var tracks: [Track]

    var body: some View {
        NavigationStack {
            Group {
                if dayLogs.isEmpty {
                    ContentUnavailableView(
                        "No history yet",
                        systemImage: "calendar",
                        description: Text("Your workout and skip logs will appear here.")
                    )
                } else {
                    List {
                        ForEach(dayLogs, id: \.persistentModelID) { log in
                            NavigationLink(value: log.persistentModelID) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(log.isSkip ? Theme.skipBlue.opacity(0.8) : Theme.batchColor(for: log.batchNumber + 1))
                                        .frame(width: 8, height: 8)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(log.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                                            .font(.subheadline.weight(.medium))
                                        if log.isSkip {
                                            Text(log.skipReason ?? "Skipped")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            let completed = log.exerciseLogs.filter(\.completed).count
                                            let total = log.exerciseLogs.count
                                            HStack(spacing: 4) {
                                                Text("\(completed)/\(total) exercises")
                                                if let score = log.wellnessScore {
                                                    Text("\u{00B7}")
                                                    Text("W: \(score)")
                                                }
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .onDelete(perform: deleteLogs)
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                DayDetailView(dayLogID: id)
            }
            .toolbar {
                if !dayLogs.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(
                            item: CSVService.writeExportFile(tracks: tracks, dayLogs: dayLogs),
                            preview: SharePreview("PT Export", image: Image(systemName: "tablecells"))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }

    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(dayLogs[index])
        }
    }
}
