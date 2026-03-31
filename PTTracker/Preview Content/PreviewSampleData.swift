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
    let context = container.mainContext

    // Seed all tracks/levels/exercises from config
    DataSeeder.seedIfNeeded(context: context)

    // Set Mat L0 as complete (all exercises at 180)
    let trackDescriptor = FetchDescriptor<Track>(sortBy: [SortDescriptor(\.sortOrder)])
    let tracks = try! context.fetch(trackDescriptor)

    let mat = tracks.first { $0.name == "Mat" }!
    let ball = tracks.first { $0.name == "Ball" }!

    // Complete Mat L0
    let matL0 = mat.levels.first { $0.levelNumber == 0 }!
    for ex in matL0.exercises { ex.currentDuration = 180 }

    // Mat L1 in progress
    let matL1 = mat.levels.first { $0.levelNumber == 1 }!
    let matL1Durations = [150, 140, 130, 140, 130]
    for (i, ex) in matL1.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
        ex.currentDuration = matL1Durations[i]
    }

    // Ball L0 in progress
    let ballL0 = ball.levels.first { $0.levelNumber == 0 }!
    for ex in ballL0.exercises { ex.currentDuration = 110 }

    // Generate ~50 days of sample history
    let calendar = Calendar.current
    let today = Date.now.startOfDay
    var dayOffset = -49

    // Helper to create workout logs
    func addWorkout(daysAgo: Int, batch: Int, exercises: [(String, Int, Bool)]) {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!.startOfDay
        let log = DayLog(date: date, isSkip: false, batchNumber: batch)
        for (name, dur, completed) in exercises {
            log.exerciseLogs.append(ExerciseLog(exerciseName: name, durationUsed: dur, completed: completed))
        }
        context.insert(log)
    }

    func addSkip(daysAgo: Int, batch: Int, reason: String) {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!.startOfDay
        let log = DayLog(date: date, isSkip: true, skipReason: reason, batchNumber: batch)
        context.insert(log)
    }

    // Batch 0 (Mat L1) — days 49-40
    let matL0Exercises = ["Supine Marches", "Prone Alternating Hip Extension", "Bridges", "Ball Squeezes", "Clam With Yellow Tubing"]
    for day in stride(from: 49, through: 40, by: -1) {
        let dur = 90 + (49 - day) * 10
        addWorkout(daysAgo: day, batch: 0, exercises: matL0Exercises.map { ($0, min(dur, 180), true) })
    }

    // Skip day 39 — fatigue
    addSkip(daysAgo: 39, batch: 0, reason: "PEM")

    // More batch 0 — days 38-36
    for day in stride(from: 38, through: 36, by: -1) {
        addWorkout(daysAgo: day, batch: 0, exercises: matL0Exercises.map { ($0, 180, true) })
    }

    // Batch 1 (Mat L2 + Ball L1) — days 35-26
    let batch1Exercises = [
        ("Supine Kickouts", true), ("Prone Swimmer", true), ("Bridges With Ball Squeezes", true),
        ("Ball Squeezes", true), ("Clam With Green Tubing", true),
        ("Seated Alternating Heel Ups", true), ("Bridging With Legs On Ball", true), ("Ball Multifidus", true),
    ]
    for day in stride(from: 35, through: 26, by: -1) {
        let dur = 90 + (35 - day) * 10
        addWorkout(daysAgo: day, batch: 1, exercises: batch1Exercises.map { ($0.0, min(dur, 180), $0.1) })
    }

    // Skip day 25 — pain
    addSkip(daysAgo: 25, batch: 1, reason: "Increased Pain")

    // Skip day 24 — pain
    addSkip(daysAgo: 24, batch: 1, reason: "Increased Pain")

    // More batch 1 — days 23-19
    for day in stride(from: 23, through: 19, by: -1) {
        addWorkout(daysAgo: day, batch: 1, exercises: batch1Exercises.map { ($0.0, 180, true) })
    }

    // Skip day 18 — fatigue
    addSkip(daysAgo: 18, batch: 1, reason: "PEM")

    // Batch 1 completion — days 17-15
    for day in stride(from: 17, through: 15, by: -1) {
        addWorkout(daysAgo: day, batch: 1, exercises: batch1Exercises.map { ($0.0, 180, true) })
    }

    // Batch 2 (Mat L3 + Ball L2) — days 14-8
    let batch2Exercises = [
        ("Dying Bug", true), ("Prone Swimmer", true), ("Bridges With Kickouts", true),
        ("Clam With Blue Tubing", true), ("Clam With Black Tubing", true), ("Ball Squeezes", true),
        ("Seated On Ball Marches", true), ("Roll Out On The Ball", true),
        ("Bridging On Ball Arms Across Chest", true), ("Hug Ball Kickout Toe Touching", true),
    ]
    for day in stride(from: 14, through: 8, by: -1) {
        let dur = 60 + (14 - day) * 10
        addWorkout(daysAgo: day, batch: 2, exercises: batch2Exercises.map { ($0.0, min(dur, 180), $0.1) })
    }

    // Skip day 7 — other
    addSkip(daysAgo: 7, batch: 2, reason: "Travel")

    // Skip day 6 — fatigue
    addSkip(daysAgo: 6, batch: 2, reason: "PEM")

    // Batch 2 — days 5-2 (partially complete workout on day 3)
    for day in stride(from: 5, through: 4, by: -1) {
        let dur = 60 + (14 - day) * 10
        addWorkout(daysAgo: day, batch: 2, exercises: batch2Exercises.map { ($0.0, min(dur, 180), true) })
    }
    // Partial workout on day 3
    addWorkout(daysAgo: 3, batch: 2, exercises: batch2Exercises.prefix(6).map { ($0.0, 150, true) } + batch2Exercises.suffix(4).map { ($0.0, 150, false) })

    // Day 2 — redo incomplete
    addWorkout(daysAgo: 2, batch: 2, exercises: batch2Exercises.suffix(4).map { ($0.0, 150, true) })

    // Day 1 — normal workout
    addWorkout(daysAgo: 1, batch: 2, exercises: batch2Exercises.map { ($0.0, 160, true) })

    return container
}()
