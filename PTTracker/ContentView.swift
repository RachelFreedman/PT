import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
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
                hasSeeded = true
            }
        }
    }
}
