import SwiftUI

struct RunCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title).font(.title3.weight(.semibold))
                    Text(workout.startedAt.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "figure.run").font(.title2).foregroundStyle(Theme.accent)
            }
            HStack(spacing: 32) {
                RunStat(label: "Time", value: Format.duration(workout.duration))
                RunStat(label: "Started", value: workout.startedAt.formatted(date: .omitted, time: .shortened))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1.5))
        .contentShape(Rectangle())
    }
}

struct RunStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body.monospacedDigit())
        }
    }
}
