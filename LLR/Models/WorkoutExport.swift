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
                        unit.format(kg: set.weightKg), "\(set.reps)", "0", "0", "", workout.notes, "",
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
