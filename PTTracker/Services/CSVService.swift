import Foundation
import SwiftData

enum CSVService {

    // MARK: - Export

    static func generateFullExport(tracks: [Track], dayLogs: [DayLog]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var csv = "RecordType,Track,Level,Exercise,CurrentDuration,Date,LogType,SkipReason,DurationUsed,Completed,BatchNumber,WellnessScore\n"

        // Progress rows — current state of every exercise
        for track in tracks.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            for level in track.levels.sorted(by: { $0.levelNumber < $1.levelNumber }) {
                for exercise in level.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                    let trackName = csvEscape(track.name)
                    let exName = csvEscape(exercise.name)
                    csv += "Progress,\(trackName),\(level.levelNumber),\(exName),\(exercise.currentDuration),,,,,,,"
                    csv += "\n"
                }
            }
        }

        // Log rows — workout history
        for log in dayLogs.sorted(by: { $0.date < $1.date }) {
            let dateStr = dateFormatter.string(from: log.date)
            if log.isSkip {
                let reason = csvEscape(log.skipReason ?? "")
                csv += "Log,,,,,\(dateStr),Skip,\(reason),,,\(log.batchNumber),"
                csv += "\n"
            } else if log.exerciseLogs.isEmpty {
                let ws = log.wellnessScore.map { "\($0)" } ?? ""
                csv += "Log,,,,,\(dateStr),Workout,,,,\(log.batchNumber),\(ws)"
                csv += "\n"
            } else {
                let ws = log.wellnessScore.map { "\($0)" } ?? ""
                for (i, ex) in log.exerciseLogs.enumerated() {
                    let name = csvEscape(ex.exerciseName)
                    let batch = i == 0 ? "\(log.batchNumber)" : ""
                    let score = i == 0 ? ws : ""
                    csv += "Log,,,,\(name),\(dateStr),Workout,,\(ex.durationUsed),\(ex.completed),\(batch),\(score)"
                    csv += "\n"
                }
            }
        }

        return csv
    }

    static func writeExportFile(tracks: [Track], dayLogs: [DayLog]) -> URL {
        let csv = generateFullExport(tracks: tracks, dayLogs: dayLogs)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pt_export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Import

    struct ImportResult {
        var progressRows: [ProgressRow] = []
        var logRows: [LogRow] = []
    }

    struct ProgressRow {
        let trackName: String
        let levelNumber: Int
        let exerciseName: String
        let currentDuration: Int
    }

    struct LogRow {
        let date: Date
        let isSkip: Bool
        let skipReason: String?
        let exerciseName: String?
        let durationUsed: Int?
        let completed: Bool
        let batchNumber: Int?
        let wellnessScore: Int?
    }

    static func parseCSV(_ content: String) throws -> ImportResult {
        var result = ImportResult()
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw ImportError.emptyFile }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for (lineIndex, line) in lines.dropFirst().enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            let fields = parseCSVLine(trimmed)
            guard fields.count >= 10 else {
                throw ImportError.invalidFormat(line: lineIndex + 2)
            }

            let recordType = fields[0]
            switch recordType {
            case "Progress":
                let trackName = fields[1]
                guard let levelNum = Int(fields[2]) else {
                    throw ImportError.invalidFormat(line: lineIndex + 2)
                }
                let exName = fields[3]
                guard let duration = Int(fields[4]) else {
                    throw ImportError.invalidFormat(line: lineIndex + 2)
                }
                result.progressRows.append(ProgressRow(
                    trackName: trackName,
                    levelNumber: levelNum,
                    exerciseName: exName,
                    currentDuration: duration
                ))

            case "Log":
                let dateStr = fields[5]
                guard let date = dateFormatter.date(from: dateStr) else {
                    throw ImportError.invalidFormat(line: lineIndex + 2)
                }
                let logType = fields[6]
                let isSkip = logType == "Skip"
                let skipReason = isSkip && !fields[7].isEmpty ? fields[7] : nil
                let exName: String? = fields[4].isEmpty ? nil : fields[4]
                let durationUsed = Int(fields[8])
                let completed = fields[9].lowercased() == "true"
                let batchNumber: Int? = fields.count > 10 ? Int(fields[10]) : nil
                let wellnessScore: Int? = fields.count > 11 ? Int(fields[11]) : nil

                result.logRows.append(LogRow(
                    date: date,
                    isSkip: isSkip,
                    skipReason: skipReason,
                    exerciseName: exName,
                    durationUsed: durationUsed,
                    completed: completed,
                    batchNumber: batchNumber,
                    wellnessScore: wellnessScore
                ))

            default:
                throw ImportError.invalidFormat(line: lineIndex + 2)
            }
        }

        return result
    }

    static func applyImport(_ importResult: ImportResult, tracks: [Track], context: ModelContext) {
        // Apply progress rows — update exercise durations
        for row in importResult.progressRows {
            guard let track = tracks.first(where: { $0.name == row.trackName }) else { continue }
            guard let level = track.levels.first(where: { $0.levelNumber == row.levelNumber }) else { continue }
            guard let exercise = level.exercises.first(where: { $0.name == row.exerciseName }) else { continue }
            exercise.currentDuration = row.currentDuration
        }

        // Delete existing logs
        let descriptor = FetchDescriptor<DayLog>()
        if let existing = try? context.fetch(descriptor) {
            for log in existing {
                context.delete(log)
            }
        }

        // Group log rows by date and type
        struct LogKey: Hashable {
            let date: Date
            let isSkip: Bool
            let skipReason: String?
        }

        var grouped: [LogKey: [LogRow]] = [:]
        for row in importResult.logRows {
            let key = LogKey(date: row.date, isSkip: row.isSkip, skipReason: row.skipReason)
            grouped[key, default: []].append(row)
        }

        // Create DayLogs
        for (key, rows) in grouped {
            let batchNum = rows.compactMap(\.batchNumber).first ?? 0
            let wellnessScore = rows.compactMap(\.wellnessScore).first
            let dayLog = DayLog(date: key.date, isSkip: key.isSkip, skipReason: key.skipReason, batchNumber: batchNum, wellnessScore: wellnessScore)
            if !key.isSkip {
                for row in rows {
                    if let exName = row.exerciseName {
                        let exLog = ExerciseLog(
                            exerciseName: exName,
                            durationUsed: row.durationUsed ?? 0,
                            completed: row.completed
                        )
                        dayLog.exerciseLogs.append(exLog)
                    }
                }
            }
            context.insert(dayLog)
        }

        try? context.save()
    }

    enum ImportError: LocalizedError {
        case emptyFile
        case invalidFormat(line: Int)

        var errorDescription: String? {
            switch self {
            case .emptyFile:
                return "The CSV file is empty."
            case .invalidFormat(let line):
                return "Invalid format at line \(line)."
            }
        }
    }

    // MARK: - CSV Helpers

    static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    /// Parses a single CSV line, handling quoted fields.
    static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()

        while let char = iterator.next() {
            if inQuotes {
                if char == "\"" {
                    // Peek at next
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else {
                            inQuotes = false
                            if next == "," {
                                fields.append(current)
                                current = ""
                            } else {
                                current.append(next)
                            }
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            }
        }
        fields.append(current)
        return fields
    }
}
