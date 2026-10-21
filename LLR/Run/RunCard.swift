import SwiftUI

struct RunCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title).font(.title3.weight(.semibold))
                    Text(workout.startedAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " · "
                        + workout.startedAt.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                WorkoutMenuButton(workout: workout)
                    .padding(.top, -10)
                    .padding(.trailing, -10)
            }
            HStack(spacing: 8) {
                if let km = workout.distanceKm {
                    StatTile(label: "Distance", value: km.formatted(.number.precision(.fractionLength(0...2))), unit: "km")
                }
                StatTile(label: "Time", value: Format.duration(workout.duration))
                if let km = workout.distanceKm {
                    StatTile(label: "Pace", value: RunLoad.paceLabel(secondsPerKm: RunLoad.paceSecondsPerKm(km: km, seconds: workout.duration)), unit: "/km")
                }
            }
        }
        .surfaceCard()
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
