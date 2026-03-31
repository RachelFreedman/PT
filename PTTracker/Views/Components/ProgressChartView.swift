import SwiftUI
import Charts

struct ProgressChartView: View {
    let dayLogs: [DayLog]

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let level: Int
        let isWorkout: Bool
        let color: Color
    }

    private var points: [ChartPoint] {
        dayLogs
            .sorted { $0.date < $1.date }
            .map { log in
                let level = log.batchNumber + 1
                if log.isSkip {
                    return ChartPoint(date: log.date, level: level, isWorkout: false, color: skipColor(reason: log.skipReason))
                } else {
                    return ChartPoint(date: log.date, level: level, isWorkout: true, color: Theme.batchColor(for: level))
                }
            }
    }

    private func skipColor(reason: String?) -> Color {
        switch reason?.lowercased() {
        case "pem", "fatigue", "tired": return Theme.skipBlue
        case "pain", "increased pain":  return Theme.skipGreen
        default:                         return .gray
        }
    }

    var body: some View {
        let sortedPoints = points

        if sortedPoints.isEmpty {
            Text("No data yet")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
        } else {
            Chart {
                ForEach(sortedPoints) { point in
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Batch", point.level)
                    )
                    .foregroundStyle(point.color)
                    .symbol {
                        if point.isWorkout {
                            Circle()
                                .fill(point.color)
                                .frame(width: 7, height: 7)
                        } else {
                            Circle()
                                .stroke(point.color, lineWidth: 1.5)
                                .frame(width: 7, height: 7)
                        }
                    }
                }
            }
            .chartYScale(domain: 1...16)
            .chartYAxis {
                AxisMarks(values: [1, 4, 8, 12, 16]) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.quaternary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        let day = Calendar.current.component(.day, from: date)
                        if day == 1 {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.quaternary)
                            AxisValueLabel(anchor: .top) {
                                VStack(spacing: 1) {
                                    Text("\(day)")
                                        .font(.system(size: 9))
                                    Text(date, format: .dateTime.month(.abbreviated))
                                        .font(.system(size: 8))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        } else if day % 5 == 0 {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                .foregroundStyle(.quaternary)
                            AxisValueLabel(anchor: .top) {
                                Text("\(day)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 30 * 24 * 3600)
            .frame(height: 180)
        }
    }
}
