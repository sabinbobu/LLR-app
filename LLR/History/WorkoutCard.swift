import SwiftUI

struct WorkoutCard: View {
    let workout: Workout
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(workout.title).font(.title3.weight(.semibold))
                    CategoryChip(category: workout.category)
                }
                Text(workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 32) {
                stat("Time", Format.duration(workout.duration))
                stat("Volume", "\(unit.format(kg: workout.volumeKg)) \(unit.rawValue)")
                stat("Sets", "\(workout.completedSets.count)")
                let records = workout.recordSetCount
                if records > 0 {
                    stat("PRs", "🏆 \(records)")
                }
            }
            Divider()
            ForEach(workout.orderedExercises) { entry in
                HStack(spacing: 12) {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Theme.border))
                    Text("\(entry.completedSets.count) sets \(entry.exercise?.name ?? "Exercise")")
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1.5))
        .contentShape(Rectangle())
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body.monospacedDigit())
        }
    }
}
