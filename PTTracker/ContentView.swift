import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeeded = false

    var body: some View {
        TabView {
            Tab("Today", systemImage: "house") {
                TodayView()
            }
            Tab("Progress", systemImage: "chart.bar") {
                PTProgressView()
            }
            Tab("History", systemImage: "clock") {
                HistoryView()
            }
        }
        .onAppear {
            if !hasSeeded {
                DataSeeder.seedIfNeeded(context: modelContext)
                hasSeeded = true
            }
        }
    }
}
