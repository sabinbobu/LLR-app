import Foundation
import SwiftData

struct ImportSummary: Equatable {
    var workouts = 0
    var sets = 0
    var duplicates = 0
    var newExercises: [String] = []
    var skippedTimedSets = 0
}

enum WorkoutImporter {
    /// Imported sessions become ordinary finished workouts, so prefill, records and charts use them
    /// straight away. Start time is the identity: re-importing the same (or a newer, overlapping)
    /// export only adds what isn't here yet.
    static func apply(_ parsed: WorkoutCSV.Parsed, into context: ModelContext) -> ImportSummary {
        var summary = ImportSummary(skippedTimedSets: parsed.skippedTimedSets)
        // Gym only: Kineto shares names like "Plank", and history landing there is hidden from the gym side.
        var known = (try? context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.sectionRaw == "gym" }))) ?? []
        var candidates = known.map { ExerciseMatcher.Candidate(name: $0.name, equipment: $0.equipment) }
        var resolved: [String: Exercise] = [:]
        // Whole seconds: exports carry no fractions, so a workout logged here at 09:00:00.734 must
        // still be recognised when its own export comes back as 09:00:00.
        func identity(_ date: Date) -> TimeInterval { date.timeIntervalSince1970.rounded(.down) }
        var taken = Set(((try? context.fetch(FetchDescriptor<Workout>())) ?? []).map { identity($0.startedAt) })

        func exercise(named name: String) -> Exercise {
            if let hit = resolved[name] { return hit }
            let exercise: Exercise
            if let index = ExerciseMatcher.match(name, in: candidates) {
                exercise = known[index]
            } else {
                // Unknown to the library: keep the lifter's history under their own name.
                exercise = Exercise(name: name, muscleGroup: MuscleGroup.other.rawValue, isCustom: true)
                context.insert(exercise)
                known.append(exercise)
                candidates.append(ExerciseMatcher.Candidate(name: name, equipment: []))
                summary.newExercises.append(name)
            }
            resolved[name] = exercise
            return exercise
        }

        for imported in parsed.workouts {
            guard taken.insert(identity(imported.startedAt)).inserted else {
                summary.duplicates += 1
                continue
            }
            let workout = Workout(startedAt: imported.startedAt)
            workout.endedAt = imported.endedAt
            workout.name = imported.name
            workout.notes = imported.notes
            context.insert(workout)
            for (order, importedExercise) in imported.exercises.enumerated() {
                let entry = WorkoutExercise(order: order)
                context.insert(entry)
                entry.exercise = exercise(named: importedExercise.name)
                workout.exercises.append(entry)
                for (setOrder, importedSet) in importedExercise.sets.enumerated() {
                    let set = SetEntry(order: setOrder, weightKg: importedSet.weightKg, reps: importedSet.reps)
                    set.kind = importedSet.kind
                    set.durationSeconds = importedSet.durationSeconds
                    set.rir = importedSet.rir
                    set.completedAt = imported.startedAt
                    context.insert(set)
                    entry.sets.append(set)
                    summary.sets += 1
                }
            }
            summary.workouts += 1
        }
        try? context.save()
        return summary
    }
}
