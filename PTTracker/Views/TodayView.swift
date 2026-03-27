import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayLog.date, order: .reverse) private var dayLogs: [DayLog]
    @Query(sort: \Track.sortOrder) private var tracks: [Track]
    @State private var showSkipDialog = false
    @State private var navigateToWorkout = false

    private var todayLog: DayLog? {
        dayLogs.first { Calendar.current.isDateInToday($0.date) }
    }

    private var programComplete: Bool {
        ProgressionEngine.isProgramComplete(tracks: tracks)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.title2)
                    .padding(.top)

                if programComplete {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                        Text("PT Program Complete!")
                            .font(.title.bold())
                    }
                    Spacer()
                } else if let log = todayLog {
                    TodayCompletedCard(dayLog: log)
                    Spacer()
                } else {
                    CurrentBatchSummary()

                    Spacer()

                    Button {
                        navigateToWorkout = true
                    } label: {
                        Label("Start Workout", systemImage: "figure.strengthtraining.traditional")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        showSkipDialog = true
                    } label: {
                        Label("Log Skip", systemImage: "arrow.right.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("PT Tracker")
            .navigationDestination(isPresented: $navigateToWorkout) {
                WorkoutSessionView()
            }
            .confirmationDialog("Skip today's workout?", isPresented: $showSkipDialog) {
                Button("PEM") { logSkip(reason: "PEM") }
                Button("Increased Pain") { logSkip(reason: "Increased Pain") }
                Button("Other reason") { logSkip(reason: nil) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Select a reason for skipping")
            }
        }
    }

    private func logSkip(reason: String?) {
        let log = DayLog(date: Date.now.startOfDay, isSkip: true, skipReason: reason)
        modelContext.insert(log)
    }
}
