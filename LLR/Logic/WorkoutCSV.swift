import Foundation

struct ImportedSet: Equatable {
    let weightKg: Double
    let reps: Int
    let kind: SetKind
}

struct ImportedExercise: Equatable {
    let name: String
    var sets: [ImportedSet]
}

struct ImportedWorkout: Equatable {
    let name: String
    let startedAt: Date
    let endedAt: Date
    let notes: String
    var exercises: [ImportedExercise]
}

/// Reads the two exports people actually switch from. One row per set, workout fields repeated.
enum WorkoutCSV {
    enum Source: String { case hevy = "Hevy", strong = "Strong" }

    struct Parsed {
        let source: Source
        let workouts: [ImportedWorkout]
        /// LLR logs weight × reps only; cardio and timed sets (no reps) have nowhere to go.
        let skippedTimedSets: Int
    }

    enum ImportError: LocalizedError {
        case unrecognized

        var errorDescription: String? {
            "This isn't a Hevy or Strong workout export. Export again from the app's settings and pick that CSV."
        }
    }

    /// Strong's Weight column carries no unit, so the caller says which unit the file was logged in.
    static func parse(_ text: String, strongUnit: WeightUnit) throws -> Parsed {
        let rows = CSV.parse(text, delimiter: CSV.delimiter(of: text))
        guard let header = rows.first else { throw ImportError.unrecognized }
        let table = Table(header: header, rows: Array(rows.dropFirst()))
        if table.has("exercise_title"), table.has("set_type") { return parseHevy(table) }
        if table.has("Exercise Name"), table.has("Set Order") { return parseStrong(table, unit: strongUnit) }
        throw ImportError.unrecognized
    }

    private static func parseHevy(_ table: Table) -> Parsed {
        let unit: WeightUnit = table.has("weight_kg") ? .kg : .lbs
        let weightColumn = unit == .kg ? "weight_kg" : "weight_lbs"
        var builder = Builder()
        for row in table.rows {
            guard let start = hevyDate.date(from: table[row, "start_time"]) else { continue }
            let end = hevyDate.date(from: table[row, "end_time"]) ?? start
            let kind: SetKind = switch table[row, "set_type"] {
            case "warmup": .warmup
            case "dropset": .drop
            case "failure": .failure
            default: .normal
            }
            builder.add(
                workout: (table[row, "title"], start, end, table[row, "description"]),
                exercise: table[row, "exercise_title"],
                weightKg: unit.toKg(WeightUnit.parse(table[row, weightColumn]) ?? 0),
                reps: Int(table[row, "reps"]) ?? 0,
                kind: kind
            )
        }
        return Parsed(source: .hevy, workouts: builder.workouts, skippedTimedSets: builder.skipped)
    }

    private static func parseStrong(_ table: Table, unit: WeightUnit) -> Parsed {
        var builder = Builder()
        for row in table.rows {
            guard let start = strongDate.date(from: table[row, "Date"]) else { continue }
            let order = table[row, "Set Order"].uppercased()
            let kind: SetKind
            switch order {
            case "W": kind = .warmup
            case "D": kind = .drop
            case "F": kind = .failure
            default:
                // Anything that isn't a set number or a set tag isn't a set.
                guard Int(order) != nil else { continue }
                kind = .normal
            }
            builder.add(
                workout: (table[row, "Workout Name"], start, start + duration(table[row, "Duration"]), table[row, "Workout Notes"]),
                exercise: table[row, "Exercise Name"],
                weightKg: unit.toKg(WeightUnit.parse(table[row, "Weight"]) ?? 0),
                reps: Int(WeightUnit.parse(table[row, "Reps"]) ?? 0),
                kind: kind
            )
        }
        return Parsed(source: .strong, workouts: builder.workouts, skippedTimedSets: builder.skipped)
    }

    /// Strong writes durations as "2h 38m", "45m" or "30s".
    static func duration(_ text: String) -> TimeInterval {
        var total: TimeInterval = 0
        for token in text.split(separator: " ") {
            guard let unit = token.last, let value = Double(token.dropLast()) else { continue }
            switch unit {
            case "h": total += value * 3600
            case "m": total += value * 60
            case "s": total += value
            default: break
            }
        }
        return total
    }

    static let hevyDate = formatter("d MMM yyyy, HH:mm")
    static let strongDate = formatter("yyyy-MM-dd HH:mm:ss")

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}

private struct Table {
    let columns: [String: Int]
    let rows: [[String]]

    init(header: [String], rows: [[String]]) {
        var columns: [String: Int] = [:]
        for (index, raw) in header.enumerated() {
            let name = raw.trimmingCharacters(in: .whitespaces)
            if columns[name] == nil { columns[name] = index }
        }
        self.columns = columns
        self.rows = rows
    }

    func has(_ column: String) -> Bool { columns[column] != nil }

    subscript(row: [String], column: String) -> String {
        guard let index = columns[column], index < row.count else { return "" }
        return row[index].trimmingCharacters(in: .whitespaces)
    }
}

/// Groups flat set rows back into workouts and exercises. Consecutive rows with the same exercise
/// are one entry; the same exercise later in the workout is a separate entry, as it was logged.
private struct Builder {
    private(set) var workouts: [ImportedWorkout] = []
    private(set) var skipped = 0
    private var workoutKey: String?

    mutating func add(
        workout: (name: String, start: Date, end: Date, notes: String),
        exercise: String,
        weightKg: Double,
        reps: Int,
        kind: SetKind
    ) {
        guard reps > 0, !exercise.isEmpty else {
            skipped += 1
            return
        }
        let key = "\(workout.start.timeIntervalSince1970)|\(workout.name)"
        if key != workoutKey {
            workoutKey = key
            workouts.append(ImportedWorkout(
                name: workout.name, startedAt: workout.start, endedAt: max(workout.end, workout.start),
                notes: workout.notes, exercises: []
            ))
        }
        let set = ImportedSet(weightKg: weightKg, reps: reps, kind: kind)
        let last = workouts.count - 1
        if workouts[last].exercises.last?.name == exercise {
            workouts[last].exercises[workouts[last].exercises.count - 1].sets.append(set)
        } else {
            workouts[last].exercises.append(ImportedExercise(name: exercise, sets: [set]))
        }
    }
}
