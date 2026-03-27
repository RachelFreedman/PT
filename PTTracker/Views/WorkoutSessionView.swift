import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Track.sortOrder) private var tracks: [Track]
    @State private var viewModel = WorkoutViewModel()
    @State private var showFinishConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Timer display
            VStack(spacing: 8) {
                Text(timerString(viewModel.remainingSeconds))
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .contentTransition(.numericText())

                if viewModel.currentExerciseIndex < viewModel.exercises.count {
                    Text(viewModel.exercises[viewModel.currentExerciseIndex].name)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 32)

            // Timer controls
            HStack(spacing: 20) {
                if viewModel.isWorkoutComplete {
                    Button("Save & Finish") {
                        viewModel.saveWorkout(context: modelContext, tracks: tracks)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else if viewModel.isTimerRunning {
                    Button("Pause") { viewModel.pauseTimer() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                } else {
                    Button("Start") { viewModel.startTimer() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }

                if !viewModel.isWorkoutComplete {
                    Button("Skip") { viewModel.completeCurrentExercise() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }
            .padding()

            // Exercise list
            List {
                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                    HStack {
                        Image(systemName: exercise.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(exercise.completed ? .green : .secondary)
                        Text(exercise.name)
                        Spacer()
                        Text("\(exercise.targetDuration)s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .fontWeight(index == viewModel.currentExerciseIndex && !viewModel.isWorkoutComplete ? .bold : .regular)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Workout")
        .navigationBarBackButtonHidden(viewModel.isTimerRunning)
        .toolbar {
            if !viewModel.isTimerRunning && !viewModel.isWorkoutComplete {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.exercises.contains(where: \.completed) {
                            showFinishConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
        .confirmationDialog("End workout early?", isPresented: $showFinishConfirmation) {
            Button("Save completed exercises") {
                viewModel.saveWorkout(context: modelContext, tracks: tracks)
                dismiss()
            }
            Button("Discard workout", role: .destructive) {
                viewModel.cancelWorkout()
                dismiss()
            }
            Button("Continue workout", role: .cancel) {}
        } message: {
            Text("You have completed some exercises. Save progress or discard?")
        }
        .onAppear {
            viewModel.loadExercises(from: tracks)
        }
    }

    private func timerString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
