import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeeded = false

    var body: some View {
        TabView {
            Tab("Today", systemImage: "house") {
                Text("Today — coming soon")
            }
            Tab("Progress", systemImage: "chart.bar") {
                Text("Progress — coming soon")
            }
            Tab("History", systemImage: "clock") {
                Text("History — coming soon")
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
