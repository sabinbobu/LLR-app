import SwiftUI

/// Pace, speed and what the run does to the body: overall exhaustion and the muscles it loads.
/// Used live in the Add Run sheet and again on a saved run.
struct RunEffectView: View {
    let km: Double
    let seconds: Double

    private var metHours: Double { RunLoad.metHours(km: km, seconds: seconds) }
    private var overall: Double { RunLoad.overallExhaustionPercent(metHours: metHours) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 32) {
                RunStat(label: "Pace", value: "\(RunLoad.paceLabel(secondsPerKm: RunLoad.paceSecondsPerKm(km: km, seconds: seconds))) /km")
                RunStat(label: "Speed", value: "\(RunLoad.speedKmh(km: km, seconds: seconds).formatted(.number.precision(.fractionLength(1)))) km/h")
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Overall body exhaustion").font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(overall.rounded()))%").font(.subheadline.monospacedDigit())
                }
                ProgressView(value: overall, total: 100).tint(Theme.recoveryColor(100 - overall))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Muscle exhaustion").font(.subheadline.weight(.semibold))
                ForEach(RunLoad.muscleLoads(metHours: metHours), id: \.muscle) { load in
                    HStack {
                        Text(load.muscle.rawValue).font(.subheadline)
                        Spacer()
                        Text("−\(Int(load.percentDrop.rounded()))%")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Theme.recoveryColor(100 - load.percentDrop), in: Capsule())
                    }
                }
            }
            Text("An estimate from speed and duration, not a measurement. It fades over about 2–3 days.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
