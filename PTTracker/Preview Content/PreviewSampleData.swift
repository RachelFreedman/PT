import SwiftData
import Foundation

@MainActor
let previewContainer: ModelContainer = {
    let schema = Schema([
        Track.self,
        Level.self,
        Exercise.self,
        DayLog.self,
        ExerciseLog.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    // Seed sample data
    let mat = Track(name: "Mat", sortOrder: 0)
    let matL0 = Level(levelNumber: 0)
    matL0.exercises = [
        Exercise(name: "Mat L0 Ex0", sortOrder: 0, currentDuration: 120),
        Exercise(name: "Mat L0 Ex1", sortOrder: 1, currentDuration: 100),
        Exercise(name: "Mat L0 Ex2", sortOrder: 2, currentDuration: 90),
    ]
    let matL1 = Level(levelNumber: 1)
    matL1.exercises = [
        Exercise(name: "Mat L1 Ex0", sortOrder: 0),
        Exercise(name: "Mat L1 Ex1", sortOrder: 1),
        Exercise(name: "Mat L1 Ex2", sortOrder: 2),
    ]
    mat.levels = [matL0, matL1]
    container.mainContext.insert(mat)

    let ball = Track(name: "Ball", sortOrder: 1)
    let ballL0 = Level(levelNumber: 0)
    ballL0.exercises = [
        Exercise(name: "Ball L0 Ex0", sortOrder: 0),
        Exercise(name: "Ball L0 Ex1", sortOrder: 1),
        Exercise(name: "Ball L0 Ex2", sortOrder: 2),
    ]
    ball.levels = [ballL0]
    container.mainContext.insert(ball)

    // Add a sample day log
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!.startOfDay
    let log = DayLog(date: yesterday, isSkip: false)
    log.exerciseLogs = [
        ExerciseLog(exerciseName: "Mat L0 Ex0", durationUsed: 110, completed: true),
        ExerciseLog(exerciseName: "Mat L0 Ex1", durationUsed: 90, completed: true),
        ExerciseLog(exerciseName: "Mat L0 Ex2", durationUsed: 80, completed: false),
    ]
    container.mainContext.insert(log)

    let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date.now)!.startOfDay
    let skipLog = DayLog(date: twoDaysAgo, isSkip: true, skipReason: "PEM")
    container.mainContext.insert(skipLog)

    return container
}()
