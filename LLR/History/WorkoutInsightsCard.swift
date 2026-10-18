import SwiftData
import SwiftUI

/// How a finished workout moved against the one before it. Shown on the post-workout summary and
/// on the workout's page in history.
struct WorkoutInsightsCard: View {
    let workout: Workout
    /// Draws its own card background; off inside a list, where the row already is one.
    var boxed = false
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @AppStorage(StorageKey.oneRepMaxFormula) private var formula: OneRepMax.Formula = .epley

    var body: some View {
        let previous = workout.previousSameName()
        let changes = WorkoutInsights.changes(workout.insightLifts, formula: formula)
        if previous != nil || !changes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Insights").font(.headline)
                if let previous {
                    totals(WorkoutInsights.compare(workout.insightTotals, to: previous.insightTotals), since: previous.startedAt)
                }
                if !changes.isEmpty {
                    if previous != nil { Divider() }
                    Text("Estimated 1RM vs last time").font(.caption).foregroundStyle(.secondary)
                    ForEach(changes) { change in
                        HStack {
                            Text(change.name).font(.subheadline).lineLimit(1)
                            Spacer()
                            Text("\(unit.format(kg: change.estimateKg)) \(unit.rawValue)").font(.subheadline.monospacedDigit())
                            delta(change.deltaKg)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(boxed ? 16 : 0)
            .background(boxed ? Theme.card : Color.clear, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func totals(_ comparison: WorkoutInsights.Comparison, since date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("vs \(workout.title) on \(date.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 20) {
                stat("Volume", signed(comparison.volumeDeltaKg, "\(unit.format(kg: abs(comparison.volumeDeltaKg))) \(unit.rawValue)")
                    // A share that rounds to zero says nothing the kilos didn't.
                    // `%.0f`, not `Int(_:)`: against a near-zero earlier volume the share can pass Int's range.
                    + (comparison.volumePercent.flatMap { abs($0) < 0.5 ? nil : " (\(signed($0, String(format: "%.0f%%", abs($0).rounded()))))" } ?? ""))
                stat("Sets", signed(Double(comparison.setDelta), "\(abs(comparison.setDelta))"))
                stat("Time", signed(comparison.durationDelta / 60, Format.duration(abs(comparison.durationDelta))))
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold).monospacedDigit())
        }
    }

    /// "+12", "−12" or "same": the sign is said, not left to colour alone.
    private func signed(_ value: Double, _ magnitude: String) -> String {
        abs(value) < 0.05 ? "same" : (value > 0 ? "+" : "−") + magnitude
    }

    @ViewBuilder private func delta(_ kg: Double?) -> some View {
        if let kg {
            let flat = abs(unit.fromKg(kg)) < 0.05
            Label(flat ? "same" : unit.format(kg: abs(kg)), systemImage: flat ? "equal" : kg > 0 ? "arrow.up" : "arrow.down")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(flat ? Color.secondary : kg > 0 ? Color.green : Color.orange)
                .frame(width: 72, alignment: .trailing)
        } else {
            Text("first time").font(.caption).foregroundStyle(.secondary).frame(width: 72, alignment: .trailing)
        }
    }
}

extension Workout {
    var insightTotals: WorkoutInsights.Totals {
        WorkoutInsights.Totals(volumeKg: volumeKg, sets: completedSets.filter(\.kind.countsTowardProgress).count, duration: duration)
    }

    /// Each exercise with the sets it got the last time it was done before this workout.
    var insightLifts: [WorkoutInsights.Lift] {
        orderedExercises.compactMap { entry in
            guard let exercise = entry.exercise else { return nil }
            let earlier = exercise.sessions(excluding: self, section: section).filter { $0.date < startedAt }
            return WorkoutInsights.Lift(
                name: exercise.name, sets: entry.completedSets.map(\.value), previous: PreviousPerformance.latestSets(in: earlier)
            )
        }
    }

    /// The last finished workout before this one with the same name. An unnamed workout is titled
    /// by time of day, which says nothing about what was trained, so it has no counterpart.
    func previousSameName() -> Workout? {
        guard !name.isEmpty, let context = modelContext else { return nil }
        let (name, start, section) = (name, startedAt, sectionRaw)
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.name == name && $0.endedAt != nil && $0.startedAt < start && $0.sectionRaw == section },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
