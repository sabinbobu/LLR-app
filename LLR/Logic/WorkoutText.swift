import Foundation

/// A finished workout as plain text, for pasting into a chat, a coach's notes or a spreadsheet.
/// Work sets only: warm-ups are left out, as they are from volume and records everywhere else.
enum WorkoutText {
    struct SetLine {
        let kind: SetKind
        let weightKg: Double
        let reps: Int
        let durationSeconds: Int?
    }

    struct Entry {
        let name: String
        let sets: [SetLine]
    }

    static func make(
        title: String, date: Date, duration: TimeInterval, volumeKg: Double,
        unit: WeightUnit, notes: String, entries: [Entry]
    ) -> String {
        var facts = [Format.duration(duration)]
        if volumeKg > 0 { facts.append("\(unit.format(kg: volumeKg)) \(unit.rawValue)") }
        var blocks = ["\(title) · \(date.formatted(date: .abbreviated, time: .omitted))\n\(facts.joined(separator: " · "))"]

        for entry in entries {
            let work = entry.sets.filter { $0.kind != .warmup }
            guard !work.isEmpty else { continue }
            blocks.append("\(entry.name)\n\(work.map { label($0, unit: unit) }.joined(separator: ", "))")
        }
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { blocks.append(trimmed) }
        return blocks.joined(separator: "\n\n")
    }

    private static func label(_ set: SetLine, unit: WeightUnit) -> String {
        let base = set.durationSeconds.map { "\(set.reps) × \($0) s" }
            ?? "\(unit.format(kg: set.weightKg)) × \(set.reps)"
        switch set.kind {
        case .drop: return base + " (drop)"
        case .failure: return base + " (failure)"
        default: return base
        }
    }
}

extension Workout {
    func plainText(unit: WeightUnit) -> String {
        WorkoutText.make(
            title: title, date: startedAt, duration: duration, volumeKg: volumeKg, unit: unit, notes: notes,
            entries: orderedExercises.map { entry in
                WorkoutText.Entry(
                    name: entry.exercise?.name ?? "Exercise",
                    sets: entry.completedSets.map {
                        WorkoutText.SetLine(kind: $0.kind, weightKg: $0.weightKg, reps: $0.reps, durationSeconds: $0.durationSeconds)
                    }
                )
            }
        )
    }
}
