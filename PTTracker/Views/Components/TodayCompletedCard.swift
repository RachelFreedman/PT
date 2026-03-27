import SwiftUI

struct TodayCompletedCard: View {
    let dayLog: DayLog

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if dayLog.isSkip {
                Label("Skipped", systemImage: "xmark.circle")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                if let reason = dayLog.skipReason {
                    Text(reason)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Workout complete", systemImage: "checkmark.circle.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.green)
                ForEach(dayLog.exerciseLogs, id: \.persistentModelID) { log in
                    HStack {
                        Image(systemName: log.completed ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(log.completed ? .green : .red)
                            .font(.caption)
                        Text(log.exerciseName)
                            .font(.subheadline)
                        Spacer()
                        Text("\(log.durationUsed)s")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
