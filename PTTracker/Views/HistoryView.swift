import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DayLog.date, order: .reverse) private var dayLogs: [DayLog]

    var body: some View {
        NavigationStack {
            Group {
                if dayLogs.isEmpty {
                    ContentUnavailableView(
                        "No history yet",
                        systemImage: "clock",
                        description: Text("Your workout and skip logs will appear here.")
                    )
                } else {
                    List(dayLogs, id: \.persistentModelID) { log in
                        NavigationLink(value: log.persistentModelID) {
                            HStack {
                                Image(systemName: log.isSkip ? "xmark.circle" : "checkmark.circle.fill")
                                    .foregroundStyle(log.isSkip ? .orange : .green)
                                VStack(alignment: .leading) {
                                    Text(log.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                                    if log.isSkip {
                                        Text("Skipped\(log.skipReason.map { " — \($0)" } ?? "")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("\(log.exerciseLogs.count) exercises")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                DayDetailView(dayLogID: id)
            }
        }
    }
}
