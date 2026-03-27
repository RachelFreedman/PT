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

    private var timer: AnyCancellable?

    struct ExerciseState: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let targetDuration: Int
        var completed: Bool = false
    }

    func loadExercises(from tracks: [Track]) {
        let active = ProgressionEngine.activeExercises(tracks: tracks)
        exercises = active.map { exercise in
            ExerciseState(
                id: exercise.persistentModelID,
                name: exercise.name,
                targetDuration: exercise.currentDuration
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

    func completeCurrentExercise() {
        pauseTimer()
        exercises[currentExerciseIndex].completed = true

        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            remainingSeconds = exercises[currentExerciseIndex].targetDuration
        } else {
            isWorkoutComplete = true
        }
    }

    func saveWorkout(context: ModelContext, tracks: [Track]) {
        let dayLog = DayLog(date: Date.now.startOfDay, isSkip: false)

        for state in exercises {
            let exerciseLog = ExerciseLog(
                exerciseName: state.name,
                durationUsed: state.targetDuration,
                completed: state.completed
            )
            dayLog.exerciseLogs.append(exerciseLog)
        }
        context.insert(dayLog)

        // Advance durations for completed exercises
        let allExercises = tracks.flatMap { $0.levels.flatMap(\.exercises) }
        let completedModels = exercises
            .filter(\.completed)
            .compactMap { state in
                allExercises.first { $0.persistentModelID == state.id }
            }
        ProgressionEngine.advanceDurations(for: completedModels)
    }

    func cancelWorkout() {
        pauseTimer()
    }
}
