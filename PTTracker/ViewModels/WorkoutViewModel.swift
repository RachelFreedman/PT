import SwiftUI
import SwiftData
import Combine

@Observable
final class WorkoutViewModel {
    var exercises: [ExerciseState] = []
    var currentExerciseIndex: Int = 0
    var isTimerRunning: Bool = false
    var remainingSeconds: Int = 0
    var isWorkoutComplete: Bool = false
    private(set) var workoutMode: ProgressionEngine.WorkoutMode = .normal

    private var timer: AnyCancellable?

    struct ExerciseState: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let targetDuration: Int
        var completed: Bool = false
        var skipped: Bool = false
    }

    func loadExercises(from tracks: [Track], dayLogs: [DayLog]) {
        let plan = ProgressionEngine.planWorkout(tracks: tracks, dayLogs: dayLogs)
        workoutMode = plan.mode
        exercises = plan.exercises.map { exercise, duration in
            ExerciseState(
                id: exercise.persistentModelID,
                name: exercise.name,
                targetDuration: duration
            )
        }
        if let first = exercises.first {
            remainingSeconds = first.targetDuration
        }
    }

    func startTimer() {
        isTimerRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.completeCurrentExercise()
                }
            }
    }

    func pauseTimer() {
        isTimerRunning = false
        timer?.cancel()
        timer = nil
    }

    func skipCurrentExercise() {
        pauseTimer()

        if remainingSeconds <= ProgressionEngine.skipGraceSeconds {
            // Close enough — count as completed
            exercises[currentExerciseIndex].completed = true
        } else {
            // Skipped too early — not completed
            exercises[currentExerciseIndex].skipped = true
        }

        moveToNextExercise()
    }

    func completeCurrentExercise() {
        pauseTimer()
        exercises[currentExerciseIndex].completed = true
        moveToNextExercise()
    }

    private func moveToNextExercise() {
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            remainingSeconds = exercises[currentExerciseIndex].targetDuration
        } else {
            isWorkoutComplete = true
        }
    }

    var wellnessScore: Int?

    func saveWorkout(context: ModelContext, tracks: [Track]) {
        let currentBatch = ProgressionEngine.currentBatchNumber(tracks: tracks) ?? 0
        let dayLog = DayLog(date: Date.now.startOfDay, isSkip: false, batchNumber: currentBatch, wellnessScore: wellnessScore)

        for state in exercises {
            let exerciseLog = ExerciseLog(
                exerciseName: state.name,
                durationUsed: state.targetDuration,
                completed: state.completed
            )
            dayLog.exerciseLogs.append(exerciseLog)
        }
        context.insert(dayLog)

        // Only advance durations if this is a normal workout (not a repeat/redo)
        guard workoutMode == .normal else { return }

        let allExercises = tracks.flatMap { $0.levels.flatMap(\.exercises) }
        let completedModels = exercises
            .filter(\.completed)
            .compactMap { state in
                allExercises.first { $0.persistentModelID == state.id }
            }
        ProgressionEngine.advanceDurations(for: completedModels)
    }

    func selectExercise(at index: Int) {
        guard index >= 0, index < exercises.count else { return }
        pauseTimer()
        currentExerciseIndex = index
        remainingSeconds = exercises[index].targetDuration
        // Reset status so it can be re-attempted
        exercises[index].completed = false
        exercises[index].skipped = false
        isWorkoutComplete = false
    }

    func cancelWorkout() {
        pauseTimer()
    }
}
