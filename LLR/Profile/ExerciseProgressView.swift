import Charts
import SwiftUI

struct ExerciseProgressView: View {
    let exercise: Exercise
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var metric: Metric = .oneRepMax

    enum Metric: String, CaseIterable {
        case heaviest = "Heaviest Weight"
        case oneRepMax = "One Rep Max"
    }

    private var sessions: [Session] { exercise.sessions() }

    private var points: [ExerciseProgress.Point] {
        metric == .heaviest
            ? ExerciseProgress.heaviestWeightSeries(sessions)
            : ExerciseProgress.oneRepMaxSeries(sessions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if sessions.isEmpty {
                    EmptyStateCard(systemImage: "chart.bar", message: "No data yet")
                } else {
                    if let last = points.last {
                        (Text("\(unit.format(kg: last.value)) \(unit.rawValue) ").bold()
                            + Text(last.date.formatted(date: .abbreviated, time: .omitted)))
                            .font(.title3)
                    }
                    Chart(points, id: \.date) { point in
                        LineMark(x: .value("Date", point.date), y: .value(metric.rawValue, unit.fromKg(point.value)))
                        PointMark(x: .value("Date", point.date), y: .value(metric.rawValue, unit.fromKg(point.value)))
                    }
                    .foregroundStyle(Theme.accent)
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 220)

                    HStack {
                        ForEach(Metric.allCases, id: \.self) { option in
                            Button(option.rawValue) { metric = option }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundStyle(metric == option ? Color.white : Color.primary)
                                .background(metric == option ? Theme.accent : Theme.card, in: Capsule())
                                .buttonStyle(.plain)
                        }
                    }

                    if let best = ExerciseProgress.bestSet(in: sessions) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal Records").font(.title3).foregroundStyle(.secondary)
                            LabeledContent("Best set", value: "\(unit.format(kg: best.weightKg)) \(unit.rawValue) × \(best.reps)")
                            LabeledContent("Estimated 1RM", value: "\(unit.format(kg: OneRepMax.epley(best))) \(unit.rawValue)")
                        }
                        .padding()
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
