import SwiftUI
import SwiftData

@main
struct PTTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Track.self,
            Level.self,
            Exercise.self,
            DayLog.self,
            ExerciseLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema migration failed — delete the old store and retry.
            // This is acceptable during development; real user data would need a proper migration.
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            // Also remove WAL/SHM files if present
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
