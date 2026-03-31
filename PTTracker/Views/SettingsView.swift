import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Track.sortOrder) private var tracks: [Track]
    @State private var showStartPointPicker = false
    @State private var showConfirmation = false
    @State private var selectedBatchIndex: Int = 0
    @State private var showImportPicker = false
    @State private var showImportConfirmation = false
    @State private var importFileURL: URL?
    @State private var importError: String?
    @State private var showImportError = false
    @State private var showImportSuccess = false
    @State private var showResetConfirmation = false

    private var batchDescriptions: [(index: Int, label: String)] {
        PTProtocolConfig.batches.enumerated().map { index, entries in
            let names = entries.map { "\($0.trackName) L\($0.levelNumber + 1)" }
            return (index, "Batch \(index + 1): \(names.joined(separator: " + "))")
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showStartPointPicker = true
                    } label: {
                        Label("Set Start Point", systemImage: "arrow.right.to.line")
                    }
                } footer: {
                    Text("Mark all exercises before a given batch as complete.")
                }

                Section {
                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Import from CSV", systemImage: "square.and.arrow.down")
                    }
                } footer: {
                    Text("Import progress and history from a previously exported CSV.")
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Everything", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("Delete all workout history and reset all exercises to the beginning.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showStartPointPicker) {
                startPointPicker
            }
            .confirmationDialog("Set start point?", isPresented: $showConfirmation, titleVisibility: .visible) {
                Button("Confirm", role: .destructive) {
                    setStartPoint(batchIndex: selectedBatchIndex)
                    showStartPointPicker = false
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Exercises before this batch will be marked complete. Exercises from this batch onward will be reset to start. History is preserved.")
            }
            .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importFileURL = url
                        showImportConfirmation = true
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                    showImportError = true
                }
            }
            .confirmationDialog("Import data?", isPresented: $showImportConfirmation, titleVisibility: .visible) {
                Button("Import", role: .destructive) { performImport() }
                Button("Cancel", role: .cancel) { importFileURL = nil }
            } message: {
                Text("This will replace all workout history. This cannot be undone.")
            }
            .alert("Import Error", isPresented: $showImportError) {
                Button("OK") {}
            } message: {
                Text(importError ?? "An unknown error occurred.")
            }
            .alert("Import Successful", isPresented: $showImportSuccess) {
                Button("OK") {}
            } message: {
                Text("Progress and history have been updated.")
            }
            .confirmationDialog("Reset everything?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { performReset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all workout history and reset all exercises to the beginning. This cannot be undone.")
            }
        }
    }

    private var startPointPicker: some View {
        NavigationStack {
            List(batchDescriptions, id: \.index) { item in
                Button {
                    selectedBatchIndex = item.index
                    showConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Theme.batchColor(for: item.index + 1))
                            .frame(width: 8, height: 8)
                        Text(item.label)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Start From Batch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showStartPointPicker = false }
                }
            }
        }
    }

    private func setStartPoint(batchIndex: Int) {
        // Mark all batches before the target as complete (only if not already)
        for i in 0..<batchIndex {
            let batch = PTProtocolConfig.batches[i]
            for entry in batch {
                guard let track = tracks.first(where: { $0.name == entry.trackName }) else { continue }
                guard let level = track.levels.first(where: { $0.levelNumber == entry.levelNumber }) else { continue }
                for exercise in level.exercises {
                    exercise.currentDuration = exercise.targetMaxDuration
                }
            }
        }

        // Reset all batches from the target onward to their config start durations
        for i in batchIndex..<PTProtocolConfig.batches.count {
            let batch = PTProtocolConfig.batches[i]
            for entry in batch {
                guard let track = tracks.first(where: { $0.name == entry.trackName }) else { continue }
                guard let level = track.levels.first(where: { $0.levelNumber == entry.levelNumber }) else { continue }
                guard let trackDef = PTProtocolConfig.tracks.first(where: { $0.name == entry.trackName }) else { continue }
                guard entry.levelNumber < trackDef.levels.count else { continue }
                let levelDef = trackDef.levels[entry.levelNumber]
                for exercise in level.exercises {
                    if let exDef = levelDef.exercises.first(where: { $0.name == exercise.name }) {
                        exercise.currentDuration = exDef.resolvedStartDuration
                    }
                }
            }
        }

        try? modelContext.save()
    }

    private func performReset() {
        // Delete all history
        let logDescriptor = FetchDescriptor<DayLog>()
        if let logs = try? modelContext.fetch(logDescriptor) {
            for log in logs { modelContext.delete(log) }
        }

        // Reset all exercises to config start durations
        for trackDef in PTProtocolConfig.tracks {
            guard let track = tracks.first(where: { $0.name == trackDef.name }) else { continue }
            for (levelNum, levelDef) in trackDef.levels.enumerated() {
                guard let level = track.levels.first(where: { $0.levelNumber == levelNum }) else { continue }
                for exercise in level.exercises {
                    if let exDef = levelDef.exercises.first(where: { $0.name == exercise.name }) {
                        exercise.currentDuration = exDef.resolvedStartDuration
                    }
                }
            }
        }

        try? modelContext.save()
    }

    private func performImport() {
        guard let url = importFileURL else { return }
        defer { importFileURL = nil }

        guard url.startAccessingSecurityScopedResource() else {
            importError = "Could not access the selected file."
            showImportError = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let parsed = try CSVService.parseCSV(content)
            CSVService.applyImport(parsed, tracks: tracks, context: modelContext)
            showImportSuccess = true
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }
}
