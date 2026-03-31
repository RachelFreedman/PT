import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let dayLogID: PersistentIdentifier
    @State private var showDeleteConfirmation = false

    private var dayLog: DayLog? {
        modelContext.model(for: dayLogID) as? DayLog
    }

    var body: some View {
        Group {
            if let dayLog {
                let color = Theme.batchColor(for: dayLog.batchNumber + 1)
                List {
                    if dayLog.isSkip {
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: "moon.zzz.fill")
                                    .foregroundStyle(Theme.skipBlue)
                                Text("Rest Day")
                                    .font(.headline)
                            }
                            if let reason = dayLog.skipReason {
                                Text(reason)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        if let score = dayLog.wellnessScore {
                            Section {
                                HStack {
                                    Text("Wellness")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(score)/10 \u{2014} \(WellnessScale.label(for: score))")
                                        .font(.subheadline)
                                }
                            }
                        }
                        Section("Exercises") {
                            ForEach(dayLog.exerciseLogs, id: \.persistentModelID) { log in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(log.completed ? color : Color.secondary.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                    Text(log.exerciseName)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(log.durationUsed)s")
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }

                    Section {
                        Button("Delete Record", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .font(.subheadline)
                    }
                }
                .navigationTitle(dayLog.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .confirmationDialog("Delete this record?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(dayLog)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will remove the log entry. If today's log is deleted, the workout will reappear on the home tab.")
                }
            } else {
                ContentUnavailableView("Not found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
