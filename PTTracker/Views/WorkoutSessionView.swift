import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Track.sortOrder) private var tracks: [Track]
    @Query(sort: \DayLog.date, order: .reverse) private var dayLogs: [DayLog]
    @State private var viewModel = WorkoutViewModel()
    @State private var showFinishConfirmation = false
    @State private var showBatchCompleteAlert = false
    @State private var batchCompleteMessage = ""
    @State private var showWellnessPrompt = true
    @State private var selectedWellnessScore: Int = 0

    private var currentBatchLevel: Int {
        (ProgressionEngine.currentBatchNumber(tracks: tracks) ?? 0) + 1
    }

    var body: some View {
        ZStack {
            workoutContent

            if showWellnessPrompt {
                wellnessPromptOverlay
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isTimerRunning || showWellnessPrompt)
        .toolbar {
            if !viewModel.isTimerRunning && !viewModel.isWorkoutComplete && !showWellnessPrompt {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.exercises.contains(where: { $0.completed || $0.skipped }) {
                            showFinishConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
        .confirmationDialog("End workout early?", isPresented: $showFinishConfirmation) {
            Button("Save completed exercises") { saveAndCheckAdvancement() }
            Button("Discard workout", role: .destructive) {
                viewModel.cancelWorkout()
                dismiss()
            }
            Button("Continue workout", role: .cancel) {}
        } message: {
            Text("You have completed some exercises. Save progress or discard?")
        }
        .onAppear {
            viewModel.loadExercises(from: tracks, dayLogs: dayLogs)
        }
        .alert("Batch Complete!", isPresented: $showBatchCompleteAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(batchCompleteMessage)
        }
    }

    // MARK: - Wellness Prompt

    private var wellnessPromptOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Text("How are you feeling?")
                    .font(.title3.weight(.semibold))

                Text("\(selectedWellnessScore)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(wellnessColor)

                Text(WellnessScale.label(for: selectedWellnessScore))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 40)
                    .animation(.none, value: selectedWellnessScore)

                Slider(value: Binding(
                    get: { Double(selectedWellnessScore) },
                    set: { selectedWellnessScore = Int($0.rounded()) }
                ), in: 0...10, step: 1)
                .tint(wellnessColor)
                .padding(.horizontal, 16)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.wellnessScore = selectedWellnessScore
                    withAnimation(.easeOut(duration: 0.25)) {
                        showWellnessPrompt = false
                    }
                } label: {
                    Text("Start Workout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .controlSize(.large)

                Button("Cancel") { dismiss() }
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.subtleGradient.ignoresSafeArea())
        .transition(.opacity)
    }

    private var wellnessColor: Color {
        // Green at 0 → yellow at 5 → red at 10
        let t = Double(selectedWellnessScore) / 10.0
        if t <= 0.5 {
            return Color(red: t * 2, green: 0.7, blue: 0.3)
        } else {
            return Color(red: 0.9, green: 0.7 * (1 - (t - 0.5) * 2), blue: 0.3 * (1 - (t - 0.5) * 2))
        }
    }

    // MARK: - Workout Content

    private var workoutContent: some View {
        VStack(spacing: 0) {
            if viewModel.workoutMode != .normal {
                modeBanner
            }

            // Timer area
            VStack(spacing: 6) {
                Text(timerString(viewModel.remainingSeconds))
                    .font(.system(size: 72, weight: .thin, design: .monospaced))
                    .foregroundStyle(viewModel.isTimerRunning ? Theme.batchColor(for: currentBatchLevel) : .primary)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.1), value: viewModel.remainingSeconds)

                if viewModel.currentExerciseIndex < viewModel.exercises.count {
                    Text(viewModel.exercises[viewModel.currentExerciseIndex].name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)

            // Controls
            HStack(spacing: 16) {
                if viewModel.isWorkoutComplete {
                    Button {
                        saveAndCheckAdvancement()
                    } label: {
                        Label("Save & Finish", systemImage: "checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.batchColor(for: currentBatchLevel))
                    .controlSize(.large)
                } else if viewModel.isTimerRunning {
                    Button {
                        viewModel.pauseTimer()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    Button {
                        viewModel.startTimer()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.batchColor(for: currentBatchLevel))
                    .controlSize(.large)
                }

                if !viewModel.isWorkoutComplete {
                    Button {
                        viewModel.skipCurrentExercise()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.body)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Exercise list
            List {
                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                    Button {
                        if !viewModel.isTimerRunning {
                            viewModel.selectExercise(at: index)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(exerciseDotColor(for: exercise))
                                .frame(width: 8, height: 8)

                            Text(exercise.name)
                                .font(.subheadline)
                                .foregroundStyle(index == viewModel.currentExerciseIndex && !viewModel.isWorkoutComplete ? .primary : .secondary)

                            Spacer()

                            Text("\(exercise.targetDuration)s")
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                    .disabled(viewModel.isTimerRunning)
                    .listRowBackground(
                        index == viewModel.currentExerciseIndex && !viewModel.isWorkoutComplete
                            ? Theme.batchColor(for: currentBatchLevel).opacity(0.08)
                            : Color.clear
                    )
                }
            }
            .listStyle(.plain)
        }
    }

    private func exerciseDotColor(for exercise: WorkoutViewModel.ExerciseState) -> Color {
        if exercise.completed {
            return Theme.batchColor(for: currentBatchLevel)
        } else if exercise.skipped {
            return .orange.opacity(0.5)
        } else {
            return .secondary.opacity(0.3)
        }
    }

    @ViewBuilder
    private var modeBanner: some View {
        let (text, icon, color): (String, String, Color) = switch viewModel.workoutMode {
        case .repeatAfterGap:
            ("Repeat workout", "arrow.counterclockwise", Theme.orange)
        case .normal:
            ("", "", .clear)
        }
        if !text.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(text)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(color)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
        }
    }

    private func saveAndCheckAdvancement() {
        let batchBefore = ProgressionEngine.currentBatchNumber(tracks: tracks)
        viewModel.saveWorkout(context: modelContext, tracks: tracks)
        let batchAfter = ProgressionEngine.currentBatchNumber(tracks: tracks)

        if batchBefore != batchAfter {
            if batchAfter != nil {
                let nextLevels = ProgressionEngine.activeLevels(tracks: tracks)
                let names = nextLevels.map(\.displayName).joined(separator: " + ")
                batchCompleteMessage = "Moving on to \(names)"
            } else {
                batchCompleteMessage = "You've completed the entire PT program!"
            }
            showBatchCompleteAlert = true
        } else {
            dismiss()
        }
    }

    private func timerString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
