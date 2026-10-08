import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Writes Strong's CSV layout: Hevy imports it, Strong's own importers read it, and LLR reads it back —
/// the one format that makes leaving (or restoring) a single file away.
enum WorkoutExport {
    static let header = [
        "Date", "Workout Name", "Duration", "Exercise Name", "Set Order", "Weight",
        "Reps", "Distance", "Seconds", "Notes", "Workout Notes", "RPE",
    ]

    /// Only finished workouts and completed sets: an open session or an unticked set isn't history yet.
    static func strongCSV(_ workouts: [Workout], unit: WeightUnit) -> String {
        var lines = [CSV.line(header)]
        for workout in workouts.sorted(by: { $0.startedAt < $1.startedAt }) where workout.endedAt != nil {
            let date = WorkoutCSV.strongDate.string(from: workout.startedAt)
            let duration = durationText(workout.duration)
            for entry in workout.orderedExercises {
                guard let exercise = entry.exercise else { continue }
                let sets = entry.completedSets
                let labels = SetKind.labels(for: sets.map(\.kind))
                for (set, label) in zip(sets, labels) {
                    lines.append(CSV.line([
                        date, workout.title, duration, exercise.name, label,
                        unit.format(kg: set.weightKg), "\(set.reps)", "0", "\(set.durationSeconds ?? 0)", "", workout.notes,
                        set.rir.map { Effort.text(rir: $0, scale: .rpe) } ?? "",
                    ]))
                }
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func durationText(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }

    static let kinetoHeader = [
        "Date", "Routine Name", "Duration", "Exercise Name", "Set Order", "Reps", "Seconds",
        "Back Pain Before", "Leg Pain Before", "Back Pain After", "Leg Pain After", "Symptoms Spread", "Notes",
    ]

    /// Separate from the Strong export above: it can't carry pain, and reimporting it would turn
    /// a rehab session into gym history. A session kept only for its recorded pain (no ticked
    /// sets) still gets one row here — that's the whole point of keeping it.
    static func kinetoCSV(_ workouts: [Workout]) -> String {
        var lines = [CSV.line(kinetoHeader)]
        for workout in workouts.sorted(by: { $0.startedAt < $1.startedAt }) {
            let date = WorkoutCSV.strongDate.string(from: workout.startedAt)
            let duration = durationText(workout.duration)
            let backBefore: String = workout.backPainBefore.map(String.init) ?? ""
            let legBefore: String = workout.legPainBefore.map(String.init) ?? ""
            let backAfter: String = workout.backPainAfter.map(String.init) ?? ""
            let legAfter: String = workout.legPainAfter.map(String.init) ?? ""
            let spread: String = workout.symptomsSpread.map { $0 ? "Yes" : "No" } ?? ""
            let painFields = [backBefore, legBefore, backAfter, legAfter, spread, workout.notes]
            var wroteARow = false
            for entry in workout.orderedExercises {
                guard let exercise = entry.exercise else { continue }
                let sets = entry.completedSets
                let labels = SetKind.labels(for: sets.map(\.kind))
                for (set, label) in zip(sets, labels) {
                    lines.append(CSV.line([date, workout.title, duration, exercise.name, label, "\(set.reps)", "\(set.durationSeconds ?? 0)"] + painFields))
                    wroteARow = true
                }
            }
            if !wroteARow {
                lines.append(CSV.line([date, workout.title, duration, "", "", "", ""] + painFields))
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

struct CSVFile: Transferable {
    let name: String
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
            try Data(file.text.utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
