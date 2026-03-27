import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let dayLogID: PersistentIdentifier

    private var dayLog: DayLog? {
        modelContext.model(for: dayLogID) as? DayLog
    }

    var body: some View {
        Group {
            if let dayLog {
                List {
                    if dayLog.isSkip {
                        Section {
                            Label("Skipped", systemImage: "xmark.circle")
                                .foregroundStyle(.orange)
                            if let reason = dayLog.skipReason {
                                Text("Reason: \(reason)")
                            }
                        }
                    } else {
                        Section("Exercises") {
                            ForEach(dayLog.exerciseLogs, id: \.persistentModelID) { log in
                                HStack {
                                    Image(systemName: log.completed ? "checkmark.circle.fill" : "xmark.circle")
                                        .foregroundStyle(log.completed ? .green : .red)
                                    Text(log.exerciseName)
                                    Spacer()
                                    Text("\(log.durationUsed)s")
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(dayLog.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
            } else {
                ContentUnavailableView("Not found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
