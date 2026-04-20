import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayLog.date, order: .reverse) private var dayLogs: [DayLog]
    @Query(sort: \Track.sortOrder) private var tracks: [Track]
    @State private var showSkipDialog = false
    @State private var navigateToWorkout = false
    @State private var pendingWorkout: PendingWorkout?

    private var todayLog: DayLog? {
        dayLogs.first { Calendar.current.isDateInToday($0.date) }
    }

    private var programComplete: Bool {
        ProgressionEngine.isProgramComplete(tracks: tracks)
    }

    private var currentBatch: Int {
        ProgressionEngine.currentBatchNumber(tracks: tracks) ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.subtleGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Date header
                    Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    if programComplete {
                        Spacer()
                        completionView
                        Spacer()
                    } else if let log = todayLog {
                        ScrollView {
                            TodayCompletedCard(dayLog: log)
                                .padding(.horizontal)
                                .padding(.top, 24)
                        }
                    } else {
                        readyView
                    }
                }
            }
            .navigationTitle("PT Tracker")
            .navigationDestination(isPresented: $navigateToWorkout) {
                WorkoutSessionView(pendingWorkout: pendingWorkout)
            }
            .onAppear {
                handlePendingWorkout()
            }
            .onChange(of: navigateToWorkout) { _, isNavigating in
                if !isNavigating {
                    // Returned from workout — refresh pending state
                    handlePendingWorkout()
                }
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

    private var completionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.gradient)
            Text("Program Complete!")
                .font(.title.bold())
            Text("You did it.")
                .foregroundStyle(.secondary)
        }
    }

    private var readyView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Batch info card
            VStack(spacing: 12) {
                Text("Batch \(currentBatch + 1) of 16")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.batchColor(for: currentBatch + 1))
                    .textCase(.uppercase)
                    .tracking(1)

                let levels = ProgressionEngine.activeLevels(tracks: tracks)
                Text(levels.map(\.displayName).joined(separator: " + "))
                    .font(.title3.weight(.semibold))

                // Mini progress for active exercises
                let exercises = ProgressionEngine.activeExercises(tracks: tracks)
                let done = exercises.filter(\.isComplete).count
                let total = exercises.count
                if total > 0 {
                    ProgressView(value: Double(done), total: Double(total))
                        .tint(Theme.batchColor(for: currentBatch + 1))
                        .padding(.horizontal, 32)
                    Text("\(done)/\(total) exercises at target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                if pendingWorkout != nil {
                    Button {
                        navigateToWorkout = true
                    } label: {
                        Label("Resume Workout", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.batchColor(for: currentBatch + 1))
                    .controlSize(.large)

                    Button {
                        PendingWorkout.clear()
                        pendingWorkout = nil
                        navigateToWorkout = true
                    } label: {
                        Text("Start Over")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Button {
                        navigateToWorkout = true
                    } label: {
                        Label("Start Workout", systemImage: "figure.strengthtraining.traditional")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.batchColor(for: currentBatch + 1))
                    .controlSize(.large)
                }

                Button {
                    showSkipDialog = true
                } label: {
                    Text("Skip Today")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func logSkip(reason: String?) {
        let currentBatch = ProgressionEngine.currentBatchNumber(tracks: tracks) ?? 0
        let log = DayLog(date: Date.now.startOfDay, isSkip: true, skipReason: reason, batchNumber: currentBatch)
        modelContext.insert(log)
    }

    /// Check for a pending workout. If it's from today, keep it for resume.
    /// If it's stale (before today), save it as a partial DayLog and clear it.
    private func handlePendingWorkout() {
        guard let pending = PendingWorkout.load() else {
            pendingWorkout = nil
            return
        }

        if pending.isFromToday {
            // Still resumable — but only if we haven't already saved a log for today
            if todayLog == nil {
                pendingWorkout = pending
            } else {
                PendingWorkout.clear()
                pendingWorkout = nil
            }
        } else {
            // Stale — save as partial workout and clear
            saveStaleWorkout(pending)
            PendingWorkout.clear()
            pendingWorkout = nil
        }
    }

    private func saveStaleWorkout(_ pending: PendingWorkout) {
        let dayLog = DayLog(
            date: pending.date,
            isSkip: false,
            batchNumber: pending.batchNumber,
            wellnessScore: pending.wellnessScore
        )
        for ex in pending.exercises {
            let log = ExerciseLog(
                exerciseName: ex.exerciseName,
                durationUsed: ex.targetDuration,
                completed: ex.completed
            )
            dayLog.exerciseLogs.append(log)
        }
        modelContext.insert(dayLog)
    }
}
