import SwiftUI

struct TodayCompletedCard: View {
    let dayLog: DayLog

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if dayLog.isSkip {
                HStack(spacing: 10) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.skipBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rest Day")
                            .font(.headline)
                        if let reason = dayLog.skipReason {
                            Text(reason)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.batchColor(for: dayLog.batchNumber + 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout Complete")
                            .font(.headline)
                        if let score = dayLog.wellnessScore {
                            Text("Wellness \(score)/10 \u{2014} \(WellnessScale.label(for: score))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                ForEach(dayLog.exerciseLogs, id: \.persistentModelID) { log in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(log.completed ? Theme.batchColor(for: dayLog.batchNumber + 1) : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                        Text(log.exerciseName)
                            .font(.subheadline)
                            .foregroundStyle(log.completed ? .primary : .secondary)
                        Spacer()
                        Text("\(log.durationUsed)s")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
