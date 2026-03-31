import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Track.sortOrder) private var tracks: [Track]
    @State private var hasSeeded = false

    var body: some View {
        TabView {
            Tab("Today", systemImage: "house.fill") {
                TodayView()
            }
            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis") {
                PTProgressView()
            }
            Tab("History", systemImage: "calendar") {
                HistoryView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tint(Theme.accent)
        .onAppear {
            if !hasSeeded {
                DataSeeder.seedIfNeeded(context: modelContext)
                loadTestDataIfNeeded()
                hasSeeded = true
            }
        }
    }

    private func loadTestDataIfNeeded() {
        // Load test CSV once. Remove this method once done testing.
        let key = "testDataLoaded_v3"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let trackDescriptor = FetchDescriptor<Track>()
        if let oldTracks = try? modelContext.fetch(trackDescriptor) {
            for track in oldTracks { modelContext.delete(track) }
        }
        let logDescriptor = FetchDescriptor<DayLog>()
        if let oldLogs = try? modelContext.fetch(logDescriptor) {
            for log in oldLogs { modelContext.delete(log) }
        }
        try? modelContext.save()

        DataSeeder.seedIfNeeded(context: modelContext)

        let csv = TestDataGenerator.generateTestCSV()
        guard let parsed = try? CSVService.parseCSV(csv) else { return }

        let freshDescriptor = FetchDescriptor<Track>(sortBy: [SortDescriptor(\.sortOrder)])
        guard let freshTracks = try? modelContext.fetch(freshDescriptor) else { return }

        CSVService.applyImport(parsed, tracks: freshTracks, context: modelContext)
        UserDefaults.standard.set(true, forKey: key)
    }
}
