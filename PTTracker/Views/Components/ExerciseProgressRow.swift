import SwiftUI

struct ExerciseProgressRow: View {
    let name: String
    let currentDuration: Int
    let minDuration: Int = 90
    let maxDuration: Int = 180

    private var progress: Double {
        Double(currentDuration - minDuration) / Double(maxDuration - minDuration)
    }

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            Spacer()
            Text("\(currentDuration)s")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            ProgressView(value: progress)
                .frame(width: 60)
        }
    }
}
