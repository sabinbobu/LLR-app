import Foundation
import SwiftData

extension WorkoutFactory {
    /// A run is logged after the fact: distance and time are known, so it is stored finished.
    @MainActor
    @discardableResult
    static func addRun(distanceKm: Double, seconds: Double, finishedAt: Date, in context: ModelContext) -> Workout {
        let run = Workout(startedAt: finishedAt.addingTimeInterval(-seconds))
        run.sectionRaw = RunStats.sectionRaw
        run.distanceKm = distanceKm
        run.endedAt = finishedAt
        context.insert(run)
        try? context.save()
        TrainingSnapshotSync.sync(context: context)
        return run
    }

    /// The first run feature was a stopwatch; one left running by it has no distance and nothing
    /// to resume into, so it is dropped rather than shown as an unfinished workout.
    static func discardUnfinishedRuns(in context: ModelContext) {
        let open = (try? context.fetch(FetchDescriptor<Workout>(predicate: #Predicate { $0.endedAt == nil && $0.sectionRaw == "run" }))) ?? []
        for run in open { context.delete(run) }
        try? context.save()
    }
}
