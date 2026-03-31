import SwiftUI

struct ExerciseProgressRow: View {
    let exercise: Exercise
    var accentColor: Color = Theme.accent

    private var progress: Double {
        let range = exercise.targetMaxDuration - exercise.startDuration
        guard range > 0 else { return 1.0 }
        return Double(exercise.currentDuration - exercise.startDuration) / Double(range)
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(exercise.isComplete ? accentColor : accentColor.opacity(0.3))
                .frame(width: 6, height: 6)

            Text(exercise.name)
                .font(.subheadline)
                .foregroundStyle(exercise.isComplete ? .secondary : .primary)

            Spacer()

            Text("\(exercise.currentDuration)s")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.tertiary)

            ProgressView(value: progress)
                .tint(accentColor)
                .frame(width: 48)
        }
    }
}
