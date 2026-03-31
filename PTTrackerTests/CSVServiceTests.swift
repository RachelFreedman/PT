import XCTest
import SwiftData
@testable import PTTracker

final class CSVServiceTests: XCTestCase {

    // A sample CSV simulating a user partway through Batch 1 (Mat L2 + Ball L1)
    // with a few days of workout history.
    let sampleCSV = """
    RecordType,Track,Level,Exercise,CurrentDuration,Date,LogType,SkipReason,DurationUsed,Completed,BatchNumber,WellnessScore
    Progress,Mat,0,Supine Marches,180,,,,,,,,
    Progress,Mat,0,Prone Alternating Hip Extension,180,,,,,,,,
    Progress,Mat,0,Bridges,180,,,,,,,,
    Progress,Mat,0,Ball Squeezes,180,,,,,,,,
    Progress,Mat,0,Clam With Yellow Tubing,180,,,,,,,,
    Progress,Mat,1,Supine Kickouts,130,,,,,,,,
    Progress,Mat,1,Prone Swimmer,120,,,,,,,,
    Progress,Mat,1,Bridges With Ball Squeezes,110,,,,,,,,
    Progress,Mat,1,Ball Squeezes,140,,,,,,,,
    Progress,Mat,1,Clam With Green Tubing,120,,,,,,,,
    Progress,Ball,0,Seated Alternating Heel Ups,100,,,,,,,,
    Progress,Ball,0,Bridging With Legs On Ball,100,,,,,,,,
    Progress,Ball,0,Ball Multifidus,100,,,,,,,,
    Log,,,,Supine Marches,2026-03-20,Workout,,170,true,0,2
    Log,,,,Prone Alternating Hip Extension,2026-03-20,Workout,,170,true,,
    Log,,,,Bridges,2026-03-20,Workout,,170,true,,
    Log,,,,Ball Squeezes,2026-03-20,Workout,,170,true,,
    Log,,,,Clam With Yellow Tubing,2026-03-20,Workout,,170,true,,
    Log,,,,,2026-03-21,Skip,PEM,,,0,
    Log,,,,Supine Kickouts,2026-03-25,Workout,,120,true,1,4
    Log,,,,Prone Swimmer,2026-03-25,Workout,,110,true,,,
    Log,,,,Bridges With Ball Squeezes,2026-03-25,Workout,,100,false,,,
    Log,,,,Ball Squeezes,2026-03-25,Workout,,130,true,,,
    Log,,,,Clam With Green Tubing,2026-03-25,Workout,,110,true,,,
    """

    // MARK: - Parse Tests

    func testParseCSV_progressRows() throws {
        let result = try CSVService.parseCSV(sampleCSV)

        XCTAssertEqual(result.progressRows.count, 13)

        // Mat L0 exercises should all be at 180 (complete)
        let matL0 = result.progressRows.filter { $0.trackName == "Mat" && $0.levelNumber == 0 }
        XCTAssertEqual(matL0.count, 5)
        XCTAssertTrue(matL0.allSatisfy { $0.currentDuration == 180 })

        // Mat L1 exercises should be in progress
        let matL1 = result.progressRows.filter { $0.trackName == "Mat" && $0.levelNumber == 1 }
        XCTAssertEqual(matL1.count, 5)
        let kickouts = matL1.first { $0.exerciseName == "Supine Kickouts" }
        XCTAssertEqual(kickouts?.currentDuration, 130)

        // Ball L0 exercises
        let ballL0 = result.progressRows.filter { $0.trackName == "Ball" && $0.levelNumber == 0 }
        XCTAssertEqual(ballL0.count, 3)
        XCTAssertTrue(ballL0.allSatisfy { $0.currentDuration == 100 })
    }

    func testParseCSV_logRows() throws {
        let result = try CSVService.parseCSV(sampleCSV)

        XCTAssertEqual(result.logRows.count, 11)

        // Skip log
        let skips = result.logRows.filter { $0.isSkip }
        XCTAssertEqual(skips.count, 1)
        XCTAssertEqual(skips.first?.skipReason, "PEM")

        // Workout on 2026-03-20 — 5 exercises all completed
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let march20 = dateFormatter.date(from: "2026-03-20")!
        let march20Logs = result.logRows.filter { !$0.isSkip && Calendar.current.isDate($0.date, inSameDayAs: march20) }
        XCTAssertEqual(march20Logs.count, 5)
        XCTAssertTrue(march20Logs.allSatisfy { $0.completed })

        // Workout on 2026-03-25 — one exercise not completed
        let march25 = dateFormatter.date(from: "2026-03-25")!
        let march25Logs = result.logRows.filter { !$0.isSkip && Calendar.current.isDate($0.date, inSameDayAs: march25) }
        XCTAssertEqual(march25Logs.count, 5)
        let incomplete = march25Logs.filter { !$0.completed }
        XCTAssertEqual(incomplete.count, 1)
        XCTAssertEqual(incomplete.first?.exerciseName, "Bridges With Ball Squeezes")
    }

    func testParseCSV_wellnessScores() throws {
        let result = try CSVService.parseCSV(sampleCSV)

        // First workout (March 20) should have wellness score 2
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let march20 = dateFormatter.date(from: "2026-03-20")!
        let march20Rows = result.logRows.filter { !$0.isSkip && Calendar.current.isDate($0.date, inSameDayAs: march20) }
        let score20 = march20Rows.compactMap(\.wellnessScore).first
        XCTAssertEqual(score20, 2)

        // Second workout (March 25) should have wellness score 4
        let march25 = dateFormatter.date(from: "2026-03-25")!
        let march25Rows = result.logRows.filter { !$0.isSkip && Calendar.current.isDate($0.date, inSameDayAs: march25) }
        let score25 = march25Rows.compactMap(\.wellnessScore).first
        XCTAssertEqual(score25, 4)

        // Skip day should have no wellness score
        let skipRows = result.logRows.filter(\.isSkip)
        XCTAssertTrue(skipRows.allSatisfy { $0.wellnessScore == nil })
    }

    @MainActor
    func testApplyImport_setsWellnessScore() throws {
        let (container, tracks) = try createSeededContainer()
        let context = container.mainContext
        let parsed = try CSVService.parseCSV(sampleCSV)

        CSVService.applyImport(parsed, tracks: tracks, context: context)

        let descriptor = FetchDescriptor<DayLog>(sortBy: [SortDescriptor(\.date)])
        let logs = try context.fetch(descriptor)
        let workoutLogs = logs.filter { !$0.isSkip }.sorted { $0.date < $1.date }

        XCTAssertEqual(workoutLogs[0].wellnessScore, 2)
        XCTAssertEqual(workoutLogs[1].wellnessScore, 4)
    }

    func testParseCSV_emptyFile() {
        XCTAssertThrowsError(try CSVService.parseCSV("")) { error in
            XCTAssertTrue(error is CSVService.ImportError)
        }
    }

    func testParseCSV_invalidLine() {
        let bad = """
        RecordType,Track,Level,Exercise,CurrentDuration,Date,LogType,SkipReason,DurationUsed,Completed,BatchNumber,WellnessScore
        Garbage,only,three,fields
        """
        XCTAssertThrowsError(try CSVService.parseCSV(bad)) { error in
            let importError = error as? CSVService.ImportError
            XCTAssertNotNil(importError)
            if case .invalidFormat(let line) = importError {
                XCTAssertEqual(line, 2)
            } else {
                XCTFail("Expected invalidFormat error")
            }
        }
    }

    // MARK: - CSV Line Parser Tests

    func testParseCSVLine_simple() {
        let fields = CSVService.parseCSVLine("a,b,c")
        XCTAssertEqual(fields, ["a", "b", "c"])
    }

    func testParseCSVLine_quoted() {
        let fields = CSVService.parseCSVLine("\"hello, world\",b,c")
        XCTAssertEqual(fields, ["hello, world", "b", "c"])
    }

    func testParseCSVLine_escapedQuotes() {
        let fields = CSVService.parseCSVLine("\"she said \"\"hi\"\"\",b")
        XCTAssertEqual(fields, ["she said \"hi\"", "b"])
    }

    func testParseCSVLine_emptyFields() {
        let fields = CSVService.parseCSVLine("a,,c,,e")
        XCTAssertEqual(fields, ["a", "", "c", "", "e"])
    }

    // MARK: - Apply Import Tests (in-memory SwiftData)

    @MainActor
    func testApplyImport_setsExerciseDurations() throws {
        let (container, tracks) = try createSeededContainer()
        let context = container.mainContext
        let parsed = try CSVService.parseCSV(sampleCSV)

        CSVService.applyImport(parsed, tracks: tracks, context: context)

        // Verify Mat L0 exercises are at 180
        let mat = tracks.first { $0.name == "Mat" }!
        let matL0 = mat.levels.first { $0.levelNumber == 0 }!
        XCTAssertTrue(matL0.isComplete)
        for ex in matL0.exercises {
            XCTAssertEqual(ex.currentDuration, 180, "Expected \(ex.name) at 180 but got \(ex.currentDuration)")
        }

        // Verify Mat L1 exercises are at imported values
        let matL1 = mat.levels.first { $0.levelNumber == 1 }!
        let kickouts = matL1.exercises.first { $0.name == "Supine Kickouts" }
        XCTAssertEqual(kickouts?.currentDuration, 130)
        let swimmer = matL1.exercises.first { $0.name == "Prone Swimmer" }
        XCTAssertEqual(swimmer?.currentDuration, 120)

        // Verify Ball L0 exercises
        let ball = tracks.first { $0.name == "Ball" }!
        let ballL0 = ball.levels.first { $0.levelNumber == 0 }!
        for ex in ballL0.exercises {
            XCTAssertEqual(ex.currentDuration, 100, "Expected \(ex.name) at 100 but got \(ex.currentDuration)")
        }
    }

    @MainActor
    func testApplyImport_createsLogs() throws {
        let (container, tracks) = try createSeededContainer()
        let context = container.mainContext
        let parsed = try CSVService.parseCSV(sampleCSV)

        CSVService.applyImport(parsed, tracks: tracks, context: context)

        let descriptor = FetchDescriptor<DayLog>(sortBy: [SortDescriptor(\.date)])
        let logs = try context.fetch(descriptor)

        // Should have 3 day logs: 2 workouts + 1 skip
        XCTAssertEqual(logs.count, 3)

        let skipLog = logs.first { $0.isSkip }
        XCTAssertNotNil(skipLog)
        XCTAssertEqual(skipLog?.skipReason, "PEM")

        let workoutLogs = logs.filter { !$0.isSkip }
        XCTAssertEqual(workoutLogs.count, 2)

        // First workout (March 20) — 5 exercises, all completed
        let firstWorkout = workoutLogs[0]
        XCTAssertEqual(firstWorkout.exerciseLogs.count, 5)
        XCTAssertTrue(firstWorkout.exerciseLogs.allSatisfy { $0.completed })

        // Second workout (March 25) — 5 exercises, 1 not completed
        let secondWorkout = workoutLogs[1]
        XCTAssertEqual(secondWorkout.exerciseLogs.count, 5)
        let incompleteCount = secondWorkout.exerciseLogs.filter { !$0.completed }.count
        XCTAssertEqual(incompleteCount, 1)
    }

    @MainActor
    func testApplyImport_replacesExistingLogs() throws {
        let (container, tracks) = try createSeededContainer()
        let context = container.mainContext

        // Insert a pre-existing log
        let oldLog = DayLog(date: Date.now, isSkip: true, skipReason: "Old")
        context.insert(oldLog)
        try context.save()

        let parsed = try CSVService.parseCSV(sampleCSV)
        CSVService.applyImport(parsed, tracks: tracks, context: context)

        let descriptor = FetchDescriptor<DayLog>()
        let logs = try context.fetch(descriptor)

        // Old log should be gone — only the 3 imported ones remain
        XCTAssertEqual(logs.count, 3)
        XCTAssertFalse(logs.contains { $0.skipReason == "Old" })
    }

    // MARK: - Round-trip Test

    @MainActor
    func testExportThenImport_roundTrips() throws {
        let (container, tracks) = try createSeededContainer()
        let context = container.mainContext

        // Set some non-default durations
        let mat = tracks.first { $0.name == "Mat" }!
        let matL0 = mat.levels.first { $0.levelNumber == 0 }!
        for (i, ex) in matL0.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
            ex.currentDuration = 100 + i * 10
        }

        // Add a workout log
        let log = DayLog(date: Date.now.startOfDay, isSkip: false)
        log.exerciseLogs = [
            ExerciseLog(exerciseName: "Supine Marches", durationUsed: 100, completed: true),
            ExerciseLog(exerciseName: "Bridges", durationUsed: 110, completed: false),
        ]
        context.insert(log)
        try context.save()

        // Export
        let dayLogDescriptor = FetchDescriptor<DayLog>()
        let dayLogs = try context.fetch(dayLogDescriptor)
        let csvString = CSVService.generateFullExport(tracks: tracks, dayLogs: dayLogs)

        // Reset everything
        for ex in matL0.exercises { ex.currentDuration = ex.startDuration }
        for dl in dayLogs { context.delete(dl) }
        try context.save()

        // Re-import
        let parsed = try CSVService.parseCSV(csvString)
        CSVService.applyImport(parsed, tracks: tracks, context: context)

        // Verify durations round-tripped
        let sortedExercises = matL0.exercises.sorted(by: { $0.sortOrder < $1.sortOrder })
        for (i, ex) in sortedExercises.enumerated() {
            XCTAssertEqual(ex.currentDuration, 100 + i * 10, "Exercise \(ex.name) didn't round-trip")
        }

        // Verify log round-tripped
        let reimportedLogs = try context.fetch(FetchDescriptor<DayLog>())
        XCTAssertEqual(reimportedLogs.count, 1)
        let reimportedLog = reimportedLogs[0]
        XCTAssertFalse(reimportedLog.isSkip)
        XCTAssertEqual(reimportedLog.exerciseLogs.count, 2)

        let marches = reimportedLog.exerciseLogs.first { $0.exerciseName == "Supine Marches" }
        XCTAssertEqual(marches?.durationUsed, 100)
        XCTAssertEqual(marches?.completed, true)

        let bridges = reimportedLog.exerciseLogs.first { $0.exerciseName == "Bridges" }
        XCTAssertEqual(bridges?.durationUsed, 110)
        XCTAssertEqual(bridges?.completed, false)
    }

    // MARK: - Helpers

    @MainActor
    private func createSeededContainer() throws -> (ModelContainer, [Track]) {
        let schema = Schema([Track.self, Level.self, Exercise.self, DayLog.self, ExerciseLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        DataSeeder.seedIfNeeded(context: context)

        let descriptor = FetchDescriptor<Track>(sortBy: [SortDescriptor(\.sortOrder)])
        let tracks = try context.fetch(descriptor)
        return (container, tracks)
    }
}
